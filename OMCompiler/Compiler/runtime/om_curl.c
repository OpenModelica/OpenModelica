

#if defined(__MINGW32__)
#define CURL_STATICLIB 1
#include "systemimpl.h"
#include "settingsimpl.h"
#endif
#include <curl/curl.h>
#include "meta/meta_modelica.h"
#include "util/omc_file.h"
#include "errorext.h"

typedef struct {
  const char *url;
  void *filename;
  void *tmpFilename;
  void *nextTry;
  FILE *fout;
} pair;

static size_t writeDataCallback(char *data, size_t n, size_t l, void *fout)
{
  return fwrite(data, n, l, (FILE*) fout);
}

static void* addTransfer(CURLM *cm, void *urlPathList, int *result, int n)
{
  if (listEmpty(urlPathList)) {
    return urlPathList;
  }
  CURL *eh = curl_easy_init();
  void *first = MMC_CAR(urlPathList);
  void *rest = MMC_CDR(urlPathList);
  const char *url = MMC_STRINGDATA(MMC_CAR(MMC_CAR(first)));
  void *tmpFilename = stringAppend(MMC_CDR(first), stringAppend(mmc_mk_scon(".tmp"), intString(n)));
  const char *file = MMC_STRINGDATA(tmpFilename);
  FILE *fout = omc_fopen(file, "wb");

  if (fout == NULL) {
    c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "Failed to open file for writing: %s", &file, 1);
    *result = 0;
    return rest;
  }

  pair *p = (pair*) malloc(sizeof(pair));
  p->url = url;
  p->nextTry = MMC_CDR(MMC_CAR(first));
  p->fout = fout;
  p->filename = MMC_CDR(first);
  p->tmpFilename = tmpFilename;
#if defined(__MINGW32__)
  {
    /* mingw/windows horror, let's find the curl CA bundle! */
    char* ca_bundle_file = NULL;
    const char* omhome = SettingsImpl__getInstallationDirectoryPath();
#if defined(__MINGW64__)
// TODO AHeu: Update to use OMDEV_MSYS?
#define CURL_CA_BUNDLE_SUFFIX "/tools/msys64/ucrt64/ssl/certs/ca-bundle.crt"
#endif
    ca_bundle_file = (char*)malloc(sizeof(char*)*strlen(omhome) + strlen(CURL_CA_BUNDLE_SUFFIX) + 1);
    sprintf(ca_bundle_file, "%s/%s", omhome, CURL_CA_BUNDLE_SUFFIX);
    /* check if file exists */
    if (!SystemImpl__regularFileExists(ca_bundle_file))
    {
      /* oh nooo, this is not an installation, is just a repo, try with OMDEV */
      free(ca_bundle_file);
      omhome = getenv("OMDEV");
      ca_bundle_file = (char*)malloc(sizeof(char*)*strlen(omhome) + strlen(CURL_CA_BUNDLE_SUFFIX) + 1);
      sprintf(ca_bundle_file, "%s/%s", omhome, CURL_CA_BUNDLE_SUFFIX);
    }
    curl_easy_setopt(eh, CURLOPT_CAINFO, ca_bundle_file);
    free(ca_bundle_file);
  }
#endif
  curl_easy_setopt(eh, CURLOPT_FOLLOWLOCATION, 1);
  curl_easy_setopt(eh, CURLOPT_WRITEFUNCTION, writeDataCallback);
  curl_easy_setopt(eh, CURLOPT_URL, url);
  curl_easy_setopt(eh, CURLOPT_CONNECTTIMEOUT, 8L);
  curl_easy_setopt(eh, CURLOPT_FAILONERROR, 1);

  curl_easy_setopt(eh, CURLOPT_PRIVATE, p);
  curl_easy_setopt(eh, CURLOPT_WRITEDATA, fout);
  curl_easy_setopt(eh, CURLOPT_USERAGENT, "OpenModelica/1.0");
  curl_easy_setopt(eh, CURLOPT_VERBOSE, 0);
  curl_multi_add_handle(cm, eh);

  return rest;
}

int om_curl_multi_download(void *urlPathList, int maxParallel)
{
  CURLM *cm;
  CURLMsg *msg;
  unsigned int transfers = 0;
  int msgs_left = -1;
  int still_alive = 1;
  int result = 1;
  int transferNumber = 1;
  curl_global_init(CURL_GLOBAL_ALL);
  cm = curl_multi_init();

  curl_multi_setopt(cm, CURLMOPT_MAXCONNECTS, maxParallel);

  for (transfers = 0; transfers < maxParallel; transfers++) {
    urlPathList = addTransfer(cm, urlPathList, &result, transferNumber++);
  }

  do {
    curl_multi_perform(cm, &still_alive);

    while ((msg = curl_multi_info_read(cm, &msgs_left))) {
      pair *p;
      CURL *e = msg->easy_handle;
      curl_easy_getinfo(e, CURLINFO_PRIVATE, &p);
      FILE *fout = p->fout;
      const char *url = p->url;

      if (msg->msg == CURLMSG_DONE) {
        if (msg->data.result != CURLE_OK) {
          fclose(fout);
          const char *msgs[2] = {curl_easy_strerror(msg->data.result), url};
          omc_unlink(MMC_STRINGDATA(p->tmpFilename));
          if (listEmpty(p->nextTry)) {
            c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "Curl error for URL %s: %s", msgs, 2);
            result = 0;
            urlPathList = addTransfer(cm, urlPathList, &result, transferNumber++);
          } else {
            c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "Will try another mirror due to curl error for URL %s: %s", msgs, 2);
            urlPathList = addTransfer(cm, mmc_mk_cons(mmc_mk_cons(p->nextTry, p->filename), urlPathList), &result, transferNumber++);
            still_alive = 1;
          }
        } else {
          fclose(fout);
          if (omc_rename(MMC_STRINGDATA(p->tmpFilename), MMC_STRINGDATA(p->filename))) {
            const char *msgs[3] = {strerror(errno), MMC_STRINGDATA(p->filename), MMC_STRINGDATA(p->tmpFilename)};
            c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "Failed to rename file after downloading with curl %s %s: %s", msgs, 3);
          }
          urlPathList = addTransfer(cm, urlPathList, &result, transferNumber++);
        }
        curl_multi_remove_handle(cm, e);
        curl_easy_cleanup(e);
      }
      else { /* There should not be any other message types... Ignore it? */
      }
      free(p);
    }
    if (still_alive) {
#if LIBCURL_VERSION_NUM >= 0x071c00 /* curl_multi_wait available since 7.28.0, not on CentOS el6 */
      curl_multi_wait(cm, NULL, 0, 1000, NULL);
#else /* just sleep a bit */
      sleep(2);
#endif
    }
  } while (still_alive || !listEmpty(urlPathList));

  curl_multi_cleanup(cm);
  curl_global_cleanup();

  return result;
}
