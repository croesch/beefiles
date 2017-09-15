#!/usr/bin/python
# coding=utf-8

from lxml import etree
import resource
import argparse

def parse(fp):
    count = 0
    context = etree.iterparse(fp, events=('end',))
    for action, elem in context:
        if elem.tag=='node':
            
            name = ""
            loc_id = ""
            place = ""
            #plz = ""
            country = ""

            for tag in elem.findall('tag'):
              #print("tag: "+str(tag.attrib))
              key = tag.get('k')
              if key is not None:
                if key == 'openGeoDB:loc_id':
                  loc_id = tag.get('v')
                #elif key == 'openGeoDB:postal_codes' or key == 'postal_code' or key == 'addr:postcode':
                #  plz = tag.get('v')
                elif key == 'name':
                  name = tag.get('v')
                elif key == 'place':
                  place = tag.get('v')
                elif key == 'is_in:country_code' or key == 'addr:country':
                  country = tag.get('v')

            if name != "" and (country == "" or country == "DE") and (loc_id != "" or place == "village" or place=="city" or place=="town" or place=="hamlet" or place=="municipality"):
              lat = elem.attrib.get('lat')
              lon = elem.attrib.get('lon')
              #print(("name="+name+", lat="+lat+", lon="+lon+", loc_id="+loc_id+", plz="+plz+", place="+place).encode('utf-8'))

              #plz_single = ""
              #if plz != "":
              #  plz_clean = plz.replace(u"–",",").replace("D-","").replace("-",",").replace(";",",").replace(" ?","").replace(" ","")
              #  plz_list = plz_clean.split(",")
              #  plz_list_int = map(int,plz_list)
              #  plz_single = str(min(plz_list_int))
              print(("INSERT INTO ortschaften VALUES("+str(count)+",'"+name+"',"+lat+","+lon+"); # "+place).encode('utf-8'))
              count += 1

        if elem.tag != 'tag':
          # cleanup
          # first empty children from current element
            # This is not absolutely necessary if you are also deleting siblings,
            # but it will allow you to free memory earlier.
          elem.clear()
          # second, delete previous siblings (records)
          while elem.getprevious() is not None:
            del elem.getparent()[0]

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('file', type=str, help='the path to the osm file', metavar='osm-file')

    args = parser.parse_args()
    parse(args.file)
