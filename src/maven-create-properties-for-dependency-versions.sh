#!/usr/bin/env python3

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

def findProperties(project):
  return find(project, "properties")

def findDependencies(project):
  return find(project, "dependencies")

def containsProperties(project):
  return not (findProperties(project) is None)

def containsDependencies(project):
  return not (findDependencies(project) is None)

def addPropertiesIfNecessary(pomFile):
  if containsProperties(pomFile):
    print("already contains <properties>")
  else:
    print("adding <properties> before <dependencies>")
    parent_map = {c: p for p in pomFile.getiterator() for c in p}
    dependencies = findDependencies(pomFile)
    index = list(parent_map[dependencies]).index(dependencies)
    properties = ET.SubElement(pomFile, "{" + namespaces["ns"] + "}properties")
    properties.text = "\n    "
    properties.tail = "\n\n  "
    # move to correct position
    pomFile.remove(properties)
    pomFile.insert(index, properties)

def versionString(artifact):
  return artifact + ".version"

def extractDependencyVersions(pomFile):
  versions = {}

  dependencies = findDependencies(pomFile)
  for dependency_node in iter(dependencies, 'dependency'):
    artifactId = find(dependency_node, 'artifactId').text
    version_node = find(dependency_node, 'version')
    if not (version_node is None):
      version = version_node.text
      if not version.startswith("$"):
        print("Extracting {}'s version: {}".format(artifactId, version))
        if artifactId in versions and versions.get(artifactId) != version:
          print("[WARNING] Version conflict for artifact " + artifactId)
          print("  found version " + version)
          print("  found version " + versions.get(artifactId))
          print("  -> ignoring current occurrence")
        else:
          versions[artifactId] = version
          version_node.text = "${" + versionString(artifactId) + "}"
#      else:
#        print("{}'s version does start with '$': {}".format(artifactId, version))
  properties = find(pomFile, 'properties')
  for foundArtifact in versions:
    versionTag = ET.SubElement(properties, versionString(foundArtifact))
    versionTag.text = versions[foundArtifact]
    versionTag.tail = "\n    "
    # move to correct position
    properties.remove(versionTag)
    properties.insert(0, versionTag)

parser = argparse.ArgumentParser(description='Create properties for dependency versions in POM file.')
parser.add_argument('-f', '--file', nargs=1, type=getIt, help='the pom file', required=True)
args = parser.parse_args()

ET.register_namespace('', namespaces["ns"])

for i, file in enumerate(args.file):
  pomTree = PIParser.parse(file)
  pomFile = pomTree.getroot()
  if containsDependencies(pomFile):
    addPropertiesIfNecessary(pomFile)
    extractDependencyVersions(pomFile)
    pomTree.write(file, encoding="UTF-8", xml_declaration=True)
  else:
    print("Skipping - no dependencies.")
