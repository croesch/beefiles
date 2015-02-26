#!/usr/bin/env python3

# Example usage:
# multiple files:
# for file in $(find . -name \*pom.xml); do echo ${file}; \
#    maven-update-parent-version -f ${file} -g de.your.group.id -a your.artifact.id -v 1.7.12 | sed -e 's/^/  /g'; \
# done

import xml.etree.ElementTree as ET

import argparse

class PIParser(ET.XMLTreeBuilder):

  def __init__(self):
    ET.XMLTreeBuilder.__init__(self)
    # assumes ElementTree 1.2.X
    self._parser.CommentHandler = self.handle_comment
    self._parser.ProcessingInstructionHandler = self.handle_pi

  def close(self):
    return ET.XMLTreeBuilder.close(self)

  def handle_comment(self, data):
    self._target.start(ET.Comment, {})
    self._target.data(data)
    self._target.end(ET.Comment)

  def handle_pi(self, target, data):
    self._target.start(ET.PI, {})
    self._target.data(target + " " + data)
    self._target.end(ET.PI)

  def parse(source):
    return ET.parse(source, PIParser())


namespaces = {'ns': 'http://maven.apache.org/POM/4.0.0'}

def getIt(string):
  return string

def find(tag, child):
  return tag.find("ns:" + child, namespaces=namespaces)

def iter(tag, child):
  return tag.iterfind("ns:" + child, namespaces=namespaces)

def findParent(project):
  return find(project, "parent")

def containsParent(project):
  return (findParent(project) is not None)

def updateParentVersion(pomFile, parentGroup, parentArtifact, parentVersion):
  if containsParent(pomFile):
    parent = findParent(pomFile)

    if (find(parent, 'groupId') is not None) and (find(parent, 'artifactId') is not None):
      if (find(parent, 'groupId').text == parentGroup) and (find(parent, 'artifactId').text == parentArtifact):
        if (find(parent, 'version') is None):
          version = ET.SubElement(parent, "{" + namespaces["ns"] + "}version")
          version.tail = "\n  "
          print("WARN: parent version does not exist.")
        else:
          version = find(parent, 'version')

        if version.text != parentVersion:
          print("INFO: " + version.text + " -> " + parentVersion)
          version.text = parentVersion
          return True
        print("INFO: parent version already correct.")
      else:
        print("INFO: wrong parent! Was: " + find(parent, 'groupId').text + ":" + find(parent, 'artifactId').text)

  return False

parser = argparse.ArgumentParser(description='Create properties for dependency versions in POM file.')
parser.add_argument('-f', '--file', nargs=1, type=getIt, help='the pom file', required=True)
parser.add_argument('-g', '--group', nargs=1, type=getIt, help='the groupId of the parent', required=True)
parser.add_argument('-a', '--artifact', nargs=1, type=getIt, help='the artifactId of the parent', required=True)
parser.add_argument('-v', '--version', nargs=1, type=getIt, help='the new version of the parent', required=True)
args = parser.parse_args()

ET.register_namespace('', namespaces["ns"])

for i, file in enumerate(args.file):
  pomTree = PIParser.parse(file)
  pomFile = pomTree.getroot()
  if updateParentVersion(pomFile, args.group[0], args.artifact[0], args.version[0]):
    pomTree.write(file, encoding="UTF-8", xml_declaration=True)
