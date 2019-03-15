#!/usr/bin/env python3

# Example usage:
# multiple files:
# for file in $(find . -name \*pom.xml); do echo ${file}; \
#    maven-update-parent-version -f ${file} -g de.your.group.id -a your.artifact.id -v 7 | sed -e 's/^/  /g'; \
# done
import argparse
from subprocess import call
from subprocess import check_output

def maven_evaluate(file,expression):
  return check_output(["mvn","-q","org.apache.maven.plugins:maven-help-plugin:evaluate","-Dexpression="+expression,"-DforceStdout=true","-f",file]).decode("utf-8")

def maven_update_parent(file,newParentMajor):
  oldParentVersion = maven_evaluate(file,"project.parent.version")
  nextMajor = str(int(newParentMajor) + 1)
  call(["mvn","-q","-U","versions:update-parent","-f",file,"-DparentVersion=["+newParentMajor+","+nextMajor+")"])
  newParentVersion = maven_evaluate(file,"project.parent.version")
  
  if oldParentVersion != newParentVersion:
    print(oldParentVersion + " -> " + newParentVersion, end=' -- ', flush=True)
    return True
  else:
    print("unchanged")
    return False

def maven_increase_major_version(file,projectVersion):
  currentProjectMajor = projectVersion.split('.')[0]
  newVersion = str(int(currentProjectMajor)+1) + ".0.0-SNAPSHOT"
  call(["mvn","-q","versions:set","-DnewVersion="+newVersion,"-DprocessAllModules=true","-f",file])
  print(projectVersion + " -> " + newVersion)

def getIt(string):
  return string

parser = argparse.ArgumentParser(description='Create properties for dependency versions in POM file.')
parser.add_argument('-f', '--file', nargs=1, type=getIt, help='the pom file', required=True)
parser.add_argument('-g', '--group', nargs=1, type=getIt, help='the groupId of the parent', required=True)
parser.add_argument('-a', '--artifact', nargs=1, type=getIt, help='the artifactId of the parent', required=True)
parser.add_argument('-v', '--version', nargs=1, type=getIt, help='the new major version of the parent', required=True)
args = parser.parse_args()

for i, file in enumerate(args.file):
  print(file, end=' -- ', flush=True)
  newParentMajor = args.version[0]
  group = args.group[0]
  artifact = args.artifact[0]

  projectVersion = maven_evaluate(file,"project.version")
  if not projectVersion.endswith("-SNAPSHOT"):
    print("project version is not SNAPSHOT: " + projectVersion)
    continue

  parentGroup = maven_evaluate(file,"project.parent.groupId")
  if parentGroup != group:
    print("parent group not matching")
    continue
  parentArtifact = maven_evaluate(file,"project.parent.artifactId")
  if parentArtifact != artifact:
    print("parent artifact id not matching")
    continue

  if maven_update_parent(file, newParentMajor):
    if projectVersion.endswith(".0.0-SNAPSHOT"):
      print("Current version is already a new major version: " + projectVersion)
    else:
      print("Increasing major version", end=' -- ', flush=True)
      maven_increase_major_version(file,projectVersion)
