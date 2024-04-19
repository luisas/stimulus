#!/usr/bin/env python3

import argparse
import json
from src.data.csv import CsvProcessing
import src.data.experiments as exp


def get_args():

    "get the arguments when using from the commandline"
    
    parser = argparse.ArgumentParser(description="")
    parser.add_argument("-c", "--csv", type=str, required=True, metavar="FILE", help='The file path for the csv containing all data')
    parser.add_argument("-j", "--json", type=str, required=True, metavar="FILE", help='The json config file that hold all parameter info')
    parser.add_argument("-o", "--output", type=str, required=True, metavar="FILE", help='The output file path to write the noised csv')

    args = parser.parse_args()
    return args




def main(data_csv, config_json, out_path):
    """
    This launcher will be the connection between the csv and one json configuration.
    It should also handle some sanity checks.

    TODO what happens when the user write his own experiment class? how should he do it ? how does it integrates here?
    """
    
    # open and read Json
    config = {}
    with open(config_json, 'r') as in_json:
        config = json.load(in_json)

    # initialize the experiment class
    exp_obj = getattr(exp, config["experiment"])() 

    # initialize the csv processing class, it open and reads the csv in automatic 
    csv_obj = CsvProcessing(exp_obj, data_csv)
    
    print(csv_obj.check_and_get_categories())

    # CASE 1: SPLIT in csv, not in json --> keep the split from the csv
    if "split" in csv_obj.check_and_get_categories(): 
        if config["split"] == None:
            next
        else:
            # CASE 2: SPLIT in csv and in json --> use the split from the json
            # TODO change this behaviour to do both, maybe
            csv_obj.add_split(config["split"], force = True)   
    
    # CASE 3: SPLIT nor in csv and or json --> use the default RandomSplitter
    elif("split" not in csv_obj.check_and_get_categories() and config["split"] == None): 
        # In case no split is provided, we use the default RandomSplitter
        # TODO add warning message
        print("IN CASE 2: SPLIT nor in csv and or json --> use the default RandomSplitter")
        csv_obj.add_split(config["split"])

    # CASE 4: SPLIT in json, not in csv --> use the split from the json
    else:
        print("IN CASE 3: SPLIT in json, not in csv  or split in both--> use the split from the json")
        csv_obj.add_split(config["split"], force = True)

    # save the modified csv
    csv_obj.save(out_path)





if __name__ == "__main__":
    args = get_args()
    main(args.csv, args.json, args.output)
