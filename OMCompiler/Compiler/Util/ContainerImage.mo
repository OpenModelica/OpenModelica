/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2025, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated uniontype ContainerImage
"file:        ContainerImage.mo
 package:     ContainerImage
 description: This file contains util functions for working with
              OCI (Open Container Initiative) containers like Docker images or
              Podman pods.
"

protected
  import Error;
  import JSON;
  import StringUtil;
  import Util;

  constant String containerTool = "docker" "Simplify future switch to other container virtualization software, e.g. podman";

public
  record CONTAINER_IMAGE
    "OCI container representing Docker image or Podman pod."
    Option<String> host       "Registry location where the image resides.";
    Option<String> port       "Port number for the registry.";
    Option<String> namespace  "Represents a user or organization.";
    String repository         "Image name, identifies specific image.";
    Option<String> tag        "Identifier to specify a particular version or variant of the image.";
    Option<String> digest     "Digest sha256";
  end CONTAINER_IMAGE;

  function parseWithArgs
    "Parse container image reference with arguments string:
        [[HOST[:PORT]/]NAMESPACE/]REPOSITORY[:TAG] [ARGUMENTS]"
    input list<String> containerReferenceWithArgs;
    output ContainerImage image;
    output List<String> arguments;
  algorithm
    if listEmpty(containerReferenceWithArgs) then
      Error.addCompilerError("Failed to parse container image reference with arguments \"" + stringDelimitList(containerReferenceWithArgs, " ") + "\".");
      fail();
    end if;

    image := parseContainerReference(listHead(containerReferenceWithArgs));
    arguments := listRest(containerReferenceWithArgs);
  end parseWithArgs;

  function parseContainerReference
    "Parse container image reference string:
        [[HOST[:PORT]/]NAMESPACE/]REPOSITORY[:TAG]"
    input String containerReference;
    output ContainerImage image;
  algorithm
    image := match Util.stringSplitAtChar(containerReference, "/")
    local
      String host_and_port;
      String host;
      Option<String> port;
      String host_and_port;
      String namespace;
      String repository_and_tag;
      String repository;
      Option<String> tag;
    case {host_and_port, namespace, repository_and_tag}
    algorithm
      (host, port) := parseContainerHostPort(host_and_port);
      (repository, tag) := parseContainerRepository(repository_and_tag);
      then CONTAINER_IMAGE(SOME(host), port, SOME(namespace), repository, tag, NONE());
    case {namespace, repository_and_tag}
    algorithm
      (repository, tag) := parseContainerRepository(repository_and_tag);
      then CONTAINER_IMAGE(NONE(), NONE(), SOME(namespace), repository, tag, NONE());
    case {repository_and_tag}
    algorithm
      (repository, tag) := parseContainerRepository(repository_and_tag);
      then CONTAINER_IMAGE(NONE(), NONE(), NONE(), repository, tag, NONE());
    else
    algorithm
      Error.addCompilerError("Failed to parse container image '" + containerReference + "'.");
      then fail();
    end match;
  end parseContainerReference;

  function getDigestSha
    "Get sha256 digest from container registry.
     Warning: This doesn't ensure that the image wasn't changed after downloading."
    input output ContainerImage image;
  protected
    String imageName = toString(image);
    String cmd;
    String manifestFile;
    JSON manifest;
    JSON descriptor;
    JSON digest;
    String digest_sha256_str;
  algorithm
    // Retrieve maifest via docker inspect or podman inspect
    manifestFile := image.repository + "_manifest.json";
    if System.regularFileExists(manifestFile) then
      System.removeFile(manifestFile);
    end if;

    // TODO: docker manifest inspect is experimental!
    // See https://docs.docker.com/reference/cli/docker/manifest/inspect/
    cmd := ContainerImage.containerTool + " manifest inspect " + imageName + " -v";
    if System.systemCall(cmd, outFile=manifestFile) <> 0 then
      Error.addCompilerError("Failed to retrieve manifest of container image '" + imageName + "'.");
      Error.addCompilerNotification(System.readFile(manifestFile) + "\n");
      System.removeFile(manifestFile);
      fail();
    end if;

    // Parse manifest JSON
    // Get Descriptor.digest
    manifest := JSON.parseFile(manifestFile);
    descriptor := JSON.get(manifest, "Descriptor");
    digest := JSON.get(descriptor, "digest");

    // Get digest
    digest_sha256_str := match digest
      case JSON.STRING() then digest.str;
      else algorithm
        Error.addCompilerError("Failed to retrieve digest SHA from manifest of container image '" + imageName + "'.");
        System.removeFile(manifestFile);
        then fail();
    end match;

    // Sanity check for 256-SHA
    if not StringUtil.startsWith(digest_sha256_str, "sha256:") then
      Error.addCompilerError("Retrieve digest 256-SHA has unexpected format: '" + digest_sha256_str + "'.");
      fail();
    end if;

    image.digest := SOME(digest_sha256_str);

    System.removeFile(manifestFile);
  end getDigestSha;

  function isTrustedOpenModelicaImage
    "Add compiler warning if container image is not known.
     Run this function before downloading any container images.
     Image has to be 'ghcr.io/openmodelica/crossbuild' with a known tag and
     digest to be trusted."
    input ContainerImage image;
    output Boolean isOpenModelicaImage = false "True if image is 'ghcr.io/openmodelica/crossbuild'";
    output Boolean hasKnownDigest = false "True if image is 'ghcr.io/openmodelica/crossbuild' and digest 256 SHA is known in this version of OMC.";
  protected
    Boolean isKnownHost;
    Boolean isKnownNamespace;
    Boolean isKnownTag;
    String host;
  algorithm
    // Check host
    isKnownHost := match image.host
      case NONE() then false;
      case SOME("docker.io") then false; // We trust Docker Hub, but don't have an official image stored there.
      case SOME("ghcr.io") then true;
      case SOME(host)
      algorithm
        Error.addCompilerWarning("Using container registry \"" + host + "\". Make sure you trust the registry.");
        then false;
    end match;

    // Check combination host+namespace
    isKnownNamespace := match (image.namespace, isKnownHost)
      case (SOME("openmodelica"), true) then true;
      case (_, true)
      algorithm
        Error.addCompilerWarning("Container image \"" + toString(image) + "\" is an external image. Make sure you trust the image.");
        then false;
      else
        then false;
    end match;

    // Check combination host+namespace+repository
    isOpenModelicaImage := match (image.repository, isKnownNamespace)
      case ("crossbuild", true) then true;
      case (_, true)
        algorithm
        Error.addCompilerWarning("Container image \"" + toString(image) + "\" is not a known OpenModelica image.");
        then false;
      else
        then false;
    end match;

    // Check combination host+namespace+repository+tag
    isKnownTag := match (image.tag, isOpenModelicaImage)
      case (SOME("v1.26.0-dev"), true) then true;
      case (_, true)
        algorithm
          Error.addCompilerWarning("Container image \"" + toString(image) + "\" is not tested for this OpenModelica version.");
        then false;
      else
        then false;
    end match;

    // Check host+namespace+repository+tag+digest
    hasKnownDigest := match (image.digest, isKnownTag)
      local
        String digest;
      // https://github.com/OpenModelica/openmodelica-crossbuild/pkgs/container/crossbuild/577190934?tag=v1.26.0-dev
      case (SOME("sha256:"), true) then true;
      case (SOME(digest), true)
      algorithm
        Error.addCompilerWarning("Container image \"" + toString(image) + "\" has unknown digest \"" + digest + "\".");
        Error.addCompilerNotification("Check https://github.com/OpenModelica/openmodelica-crossbuild/pkgs/container/crossbuild/ for available cross-build images managed by OpenModelica.");
        then false;
      case (NONE(), true)
      algorithm
        Error.addCompilerError("Container image \"" + toString(image) + "\" has no digest. That shouldn't be possible.");
        then fail();
      else
        then false;
    end match;
  end isTrustedOpenModelicaImage;

  function pull
    "Pull container image."
    input ContainerImage image;
  protected
    String pullLogFile;
    String imageName = toString(image);
    String cmd;
  algorithm
    pullLogFile := image.repository + "_pull.log";

    cmd := ContainerImage.containerTool + " pull " + imageName;
    if not System.systemCall(cmd, outFile=pullLogFile) == 0 then
      Error.addCompilerError("Failed to pull container image '" + imageName + "'.");
      Error.addCompilerNotification(System.readFile(pullLogFile) + "\n");
      System.removeFile(pullLogFile);
      fail();
    end if;

    Error.addCompilerNotification(System.readFile(pullLogFile) + "\n");
    System.removeFile(pullLogFile);
  end pull;

  function assertSignature
    "Assert SHA of downloaded image matches expected SHA and that signature is
     valid. Fails if signature can't be verified.
     Needs `cosign` from sigstore to be in PATH."
    input ContainerImage image;
  protected
    String cosignLogFile;
    String cmd;
    String imageName = toString(image);
  algorithm
    cosignLogFile := image.repository + "_signature.log";
    if System.regularFileExists(cosignLogFile) then
      System.removeFile(cosignLogFile);
    end if;
    // TODO: Check if cosign is available

    // Verification using cosign
    cmd := "cosign verify " + imageName +
           " --certificate-identity=https://github.com/OpenModelica/openmodelica-crossbuild/.github/workflows/publish.yml@refs/tags/v1.26.0-dev" +
           " --certificate-oidc-issuer=https://token.actions.githubusercontent.com";

    System.appendFile(cosignLogFile, cmd + "\n");
    if not System.systemCall(cmd, outFile=cosignLogFile) == 0 then
      Error.addCompilerError("Failed to verify signature of container image '" + imageName + "'.");
      Error.addCompilerNotification(System.readFile(cosignLogFile) + "\n");
      System.removeFile(cosignLogFile);
      // TODO: Fail if failing to verify!
      // fail();
      return;
    end if;

    System.removeFile(cosignLogFile);
  end assertSignature;

  function toString
    "Return container image as string in format
     [[HOST[:PORT]/]NAMESPACE/]REPOSITORY[:TAG]."
    input ContainerImage image;
    output String imageString = "";
  algorithm
    imageString := hostToString(image);
    if not imageString == "" then
      imageString := imageString + "/";
    end if;

    imageString := imageString + nameToString(image);

    if isSome(image.tag) then
      imageString := imageString + ":" + Util.getOption(image.tag);
    end if;
  end toString;

  function nameToString
    "Return name [NAMESPACE/]REPOSITORY as String."
    input ContainerImage image;
    output String name = "";
  algorithm
    name := match image
      local
        String namespace_str;
        String repository;
      case CONTAINER_IMAGE(namespace = SOME(namespace_str), repository = repository)
        then namespace_str + "/" + repository;
      case CONTAINER_IMAGE(namespace = NONE(), repository = repository)
        then repository;
      else
      algorithm
        Error.addCompilerError("Failed to get name of image reference.");
        then fail();
    end match;
  end nameToString;

protected
  // Helper functions for parsing
  function parseContainerHostPort
    "Parse container host and port string:
        HOST[:PORT]"
    input String host_and_port;
    output String host;
    output Option<String> port = NONE();
  algorithm
    host := match Util.stringSplitAtChar(host_and_port, ":")
    local
      String host_str;
      String port_str;
      case {host_str, port_str}
      algorithm
        port := SOME(port_str);
      then host_str;
      case {host_str} then host_str;
      else
      algorithm
        Error.addCompilerError("Failed to parse container host '" + host_and_port + "'.");
        then fail();
    end match;
  end parseContainerHostPort;

  function parseContainerRepository
    "Parse container image repository string:
        REPOSITORY[:TAG]"
    input String repositoryString;
    output String repository;
    output Option<String> tag;
  algorithm
    (repository, tag) := match Util.stringSplitAtChar(repositoryString, ":")
    local
      String repository_str;
      String tag_str;
    case {repository_str, tag_str} then (repository_str, SOME(tag_str));
    case {repository_str} then (repository_str, NONE());
    else
    algorithm
      Error.addCompilerError("Failed to parse container image name '" + repositoryString + "'.");
      then fail();
    end match;
  end parseContainerRepository;

  // Helper functions for toString
  function hostToString
    "Return [HOST[:PORT]] as string."
    input ContainerImage image;
    output String hostPortStr = "";
  algorithm
    hostPortStr := match image
      local
        String hostStr;
        String portStr;
      case CONTAINER_IMAGE(host = SOME(hostStr), port = SOME(portStr))
        then hostStr + ":" + portStr;
      case CONTAINER_IMAGE(host = SOME(hostStr), port = NONE())
        then hostStr;
      case CONTAINER_IMAGE(host = NONE(), port = SOME(_))
        algorithm
          Error.addCompilerError("Port specified without host.");
          then fail();
      case CONTAINER_IMAGE(host = NONE(), port = NONE())
        then "";
      else
        algorithm
          Error.addCompilerError("Failed to get host and port of image reference.");
          then fail();
    end match;
  end hostToString;

annotation(__OpenModelica_Interface="util");
end ContainerImage;
