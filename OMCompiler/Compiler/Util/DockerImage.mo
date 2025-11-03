/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated uniontype DockerImage
"file:        DockerImage.mo
 package:     DockerImage
 description: This file contains util functions for working with Docker images.
"

protected
  import Error;
  import Util;

public
  record DOCKER_IMAGE
    Option<String> host       "Registry location where the image resides.";
    Option<String> port       "Port number for the registry.";
    Option<String> namespace  "Represents a user or organization.";
    String repository         "Image name, identifies specific image.";
    Option<String> tag        "Identifier to specify a particular version or variant of the image.";
  end DOCKER_IMAGE;

  function parseWithArgs
    "Parse Docker image reference with arguments string:
        [[HOST[:PORT]/]NAMESPACE/]REPOSITORY[:TAG] [ARGUMENTS]"
    input List<String> dockerReferenceWithArgs;
    output DockerImage image;
    output List<String> arguments;
  algorithm
    (image, arguments) := match dockerReferenceWithArgs
    local
      String imageReferenceStr;
      List<String> rest;
    case imageReferenceStr::rest
      then(parseDockerReference(imageReferenceStr), rest);
    case {imageReferenceStr}
      then(parseDockerReference(imageReferenceStr), {});
    else
    algorithm
      Error.addCompilerError("Failed to parse Docker image reference with arguments\"" + stringDelimitList(dockerReferenceWithArgs, " ") + "\".");
      then fail();
    end match;
  end parseWithArgs;

  function parseDockerReference
    "Parse Docker image reference string:
        [[HOST[:PORT]/]NAMESPACE/]REPOSITORY[:TAG]"
    input String dockerReference;
    output DockerImage image;
  algorithm
    image := match Util.stringSplitAtChar(dockerReference, "/")
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
      (host, port) := parseDockerHostPort(host_and_port);
      (repository, tag) := parseDockerRepository(repository_and_tag);
      then(DOCKER_IMAGE(SOME(host), port, SOME(namespace), repository, tag));
    case {namespace, repository_and_tag}
    algorithm
      (repository, tag) := parseDockerRepository(repository_and_tag);
      then(DOCKER_IMAGE(NONE(), NONE(), SOME(namespace), repository, tag));
    case {repository_and_tag}
    algorithm
      (repository, tag) := parseDockerRepository(repository_and_tag);
      then(DOCKER_IMAGE(NONE(), NONE(), NONE(), repository, tag));
    else
    algorithm
      Error.addCompilerError("Failed to parse Docker image '" + dockerReference + "'.");
      then fail();
    end match;
  end parseDockerReference;

  function isTrustedOpenModelicaImage
    "Add compiler warning if Docker image is not
     'openmodelica/crossbuild:v1.26.0' from DockerHub or GitHub Container
     Registry."
    input DockerImage image;
    output Boolean isOpenModelicaImage = true;
  protected
    String host;
  algorithm
    // Check host
    isOpenModelicaImage := match image.host
      case NONE() then(isOpenModelicaImage);
      case SOME("docker.io") then(isOpenModelicaImage);
      case SOME("ghcr.io") then(isOpenModelicaImage);
      else
      algorithm
        Error.addCompilerWarning("Using Docker registry \"" + toString(image) + "\". Make sure you trust the registry.");
        then(false);
    end match;

    // Check namespace
    isOpenModelicaImage := match (image.namespace, isOpenModelicaImage)
      case (SOME("openmodelica"), true) then(isOpenModelicaImage);
      case (_, true)
      algorithm
        Error.addCompilerWarning("Docker image \"" + toString(image) + "\" is an external image. Make sure you trust the image.");
        then(false);
      else
        then(false);
    end match;

    // Check repository
    isOpenModelicaImage := match (image.repository, isOpenModelicaImage)
      case ("crossbuild", true) then(isOpenModelicaImage);
      case (_, true)
        algorithm
        Error.addCompilerWarning("Docker image \"" + toString(image) + "\" is not a known OpenModelica image.");
        then(false);
      else
        then(false);
    end match;

    // Check tag
    isOpenModelicaImage := match (image.tag, isOpenModelicaImage)
      case (SOME("v1.26.0"), true) then(isOpenModelicaImage);
      case (_, true)
        algorithm
          Error.addCompilerWarning("Docker image \"" + toString(image) + "\" is not tested for this OpenModelica version.");
        then(false);
      else
        then(false);
    end match;

    // Check sha
    //sha := getImageSHA(image);


  end isTrustedOpenModelicaImage;

  function toString
    input DockerImage image;
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
    input DockerImage image;
    output String name = "";
  algorithm
    name := match image
      local
        String namespace_str;
        String repository;
      case DOCKER_IMAGE(namespace = SOME(namespace_str), repository = repository)
        then(namespace_str + "/" + repository);
      case DOCKER_IMAGE(namespace = NONE(), repository = repository)
        then(repository);
      else
      algorithm
        Error.addCompilerError("Failed to get name of docker image reference.");
        then fail();
    end match;
  end nameToString;

protected
  // Helper functions for parsing
  function parseDockerHostPort
    "Parse Docker host and port string:
        HOST[:PORT]"
    input String host_and_port;
    output String host;
    output Option<String> port := NONE();
  algorithm
    host := match Util.stringSplitAtChar(host_and_port, ":")
    local
      String host_str;
      String port_str;
      case {host_str, port_str}
      algorithm
        port := SOME(port_str);
      then(host_str);
      case {host_str} then(host_str);
      else
      algorithm
        Error.addCompilerError("Failed to parse Docker host '" + host_and_port + "'.");
        then fail();
    end match;
  end parseDockerHostPort;

  function parseDockerRepository
    "Parse Docker image repository string:
        REPOSITORY[:TAG]"
    input String repositoryString;
    output String repository;
    output Option<String> tag;
  algorithm
    _ := match Util.stringSplitAtChar(repositoryString, ":")
    local
      String repository_str;
      String tag_str;
    case {repository_str, tag_str}
    algorithm
      repository := repository_str;
      tag := SOME(tag_str);
      then();
    case {repository_str}
    algorithm
      repository := repository_str;
      tag := NONE();
      then();
    else
    algorithm
      Error.addCompilerError("Failed to parse Docker image name '" + repositoryString + "'.");
      then fail();
    end match;
  end parseDockerRepository;

  // Helper functions for toString
  function hostToString
    "Return [HOST[:PORT]] as string."
    input DockerImage image;
    output String hostPortStr = "";
  algorithm
    hostPortStr := match image
      local
        String hostStr;
        String portStr;
      case DOCKER_IMAGE(host = SOME(hostStr), port = SOME(portStr))
        then(hostStr + ":" + portStr);
      case DOCKER_IMAGE(host = SOME(hostStr), port = NONE())
        then(hostStr);
      case DOCKER_IMAGE(host = NONE(), port = SOME(_))
        algorithm
          Error.addCompilerError("Port specified without host.");
          then fail();
      case DOCKER_IMAGE(host = NONE(), port = NONE())
        then("");
      else
        algorithm
          Error.addCompilerError("Failed to get host and port of docker image reference.");
          then fail();
    end match;
  end hostToString;

annotation(__OpenModelica_Interface="util");
end DockerImage;
