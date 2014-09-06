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

def findSCM(project):
  return find(project, "scm")

def notContainsSCM(project):
  return (findSCM(project) is None)

def setSCMTag(pomFile, connectionText):
  if notContainsSCM(pomFile):
    scm = ET.SubElement(pomFile, "{" + namespaces["ns"] + "}scm")
    scm.text = "\n    "
    scm.tail = "\n"
  else:
    scm = findSCM(pomFile)

  if (find(scm, 'connection') is None):
    connection = ET.SubElement(scm, "{" + namespaces["ns"] + "}connection")
    connection.tail = "\n  "
  else:
    connection = find(scm, 'connection')

  connection.text = connectionText

parser = argparse.ArgumentParser(description='Create properties for dependency versions in POM file.')
parser.add_argument('-f', '--file', nargs=1, type=getIt, help='the pom file', required=True)
parser.add_argument('-c', '--connection', nargs=1, type=getIt, help='the connection of the scm', required=True)
args = parser.parse_args()

ET.register_namespace('', namespaces["ns"])

for i, file in enumerate(args.file):
  pomTree = PIParser.parse(file)
  pomFile = pomTree.getroot()
  setSCMTag(pomFile, args.connection[0])
  pomTree.write(file, encoding="UTF-8", xml_declaration=True)
