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

encapsulated package Docker
"file:        Docker.mo
 package:     Docker
 description: This file contains util functions for working with Docker.
"

protected
  import Error;
  import Util;

public
  uniontype DockerImageReference
    record DOCKER_IMAGE_REFERENCE
      Option<String> host;
      Option<String> port;
      Option<String> namespace;
      String repository;
      Option<String> tag;
    end DOCKER_IMAGE_REFERENCE;
  end DockerImageReference;

  function parseDockerReferenceWithArgs
    "Parse Docker image reference with arguments string:
        [[HOST[:PORT]/]NAMESPACE/]REPOSITORY[:TAG] [ARGUMENTS]"
    input List<String> dockerReferenceWithArgs;
    output DockerImageReference reference;
    output List<String> arguments;
  algorithm
    (reference, arguments) := match dockerReferenceWithArgs
    local
      String image;
      List<String> rest;
    case image::rest
      then(parseDockerReference(image), rest);
    case {image}
      then(parseDockerReference(image), {});
    else
    algorithm
      Error.addCompilerError("Failed to parse Docker reference with arguments\"" + stringDelimitList(dockerReferenceWithArgs, " ") + "\".");
      then fail();
    end match;
  end parseDockerReferenceWithArgs;

  function warnNonOpenModelicaImage
    "Add compiler warning if Docker image isn't \"docker.io/openmodelica/crossbuild/v0.1.0\"."
    input DockerImageReference reference;
  algorithm
    _ := match reference.host
      local
        String host;
      case SOME(host)
        algorithm
        if not host == "docker.io" then
          Error.addCompilerWarning("Using non-default Docker registry \"" + host + "\". Make sure you trust the registry.");
        end if;
      then();
    end match;

    _ := match reference.namespace
      case SOME("openmodelica")
        then();
      else
      algorithm
        Error.addCompilerWarning("Docker image \"" + getName(reference) + "\" is an external image. Make sure you trust the image.");
        then();
    end match;

    if not reference.repository == "crossbuild" then
      Error.addCompilerWarning("Docker image \"" + getName(reference) + "\" is not tested for this OpenModelica version.");
    end if;

    _ := match reference.tag
    local
      String tag;
    case SOME(tag)
      algorithm
      if not tag == "v0.1.0" then
        Error.addCompilerWarning("Docker image \"" + getName(reference) + "\" is not tested for this OpenModelica version.");
      end if;
      then();
    end match;
  end warnNonOpenModelicaImage;

protected
  protected function getName
    input DockerImageReference reference;
    output String name;
  algorithm
    name := match reference
      local
        String namespace_str;
        String repository;
      case DOCKER_IMAGE_REFERENCE(namespace = SOME(namespace_str), repository = repository)
        then(namespace_str + "/" + repository);
      case DOCKER_IMAGE_REFERENCE(namespace = NONE(), repository = repository)
        then(repository);
      else
      algorithm
        Error.addCompilerError("Failed to get name of docker reference.");
        then fail();
    end match;
  end getName;

  function parseDockerReference
    "Parse Docker image reference string:
        [[HOST[:PORT]/]NAMESPACE/]REPOSITORY[:TAG]"
    input String dockerReference;
    output DockerImageReference reference;
  algorithm
    reference := match Util.stringSplitAtChar(dockerReference, "/")
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
      then(DOCKER_IMAGE_REFERENCE(SOME(host), port, SOME(namespace), repository, tag));
    case {namespace, repository_and_tag}
    algorithm
      (repository, tag) := parseDockerRepository(repository_and_tag);
      then(DOCKER_IMAGE_REFERENCE(NONE(), NONE(), SOME(namespace), repository, tag));
    case {repository_and_tag}
    algorithm
      (repository, tag) := parseDockerRepository(repository_and_tag);
      then(DOCKER_IMAGE_REFERENCE(NONE(), NONE(), NONE(), repository, tag));
    else
    algorithm
      Error.addCompilerError("Failed to parse Docker reference '" + dockerReference + "'.");
      then fail();
    end match;
  end parseDockerReference;

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
      then();
    else
    algorithm
      Error.addCompilerError("Failed to parse Docker image name '" + repositoryString + "'.");
      then fail();
    end match;
  end parseDockerRepository;

annotation(__OpenModelica_Interface="util");
end Docker;
