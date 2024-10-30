/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { INTERPRET_JSON } from '../../../modules/local/interpret_json.nf'
include { SPLIT_CSV      } from '../../../subworkflows/local/split_csv'
include { TRANSFORM_CSV  } from '../../../subworkflows/local/transform_csv'
include { SHUFFLE_CSV    } from '../../../subworkflows/local/shuffle_csv'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow HANDLE_DATA {

    take:
    input_csv
    input_json
    message_from_check


    main:

    // print the message from the check_model subworkflow
    message_from_check.view()

    // put the files in channels
    csv  = Channel.fromPath( input_csv  )
    json = Channel.fromPath( input_json )

    // read the json and create many json as there are combinations of noisers and splitters. the message_from_check is passed only to enforce that this modules does not run untill check_module is finished.
    INTERPRET_JSON( json, message_from_check )

    csv.view()

    // the above process outputs three channels one with all the information (split+ transform), one with only split info, and one with only transform. Each of this channels have to be transformed into a tuple with a common unique id for a given combination.
    experiment_json = INTERPRET_JSON.out.experiment_json.flatten().map{
        it -> [["split": "${it.baseName}".split('-')[0..-2].join("-")], it]
    }

    // the split has only the keyword to match to the transform
    split_json = INTERPRET_JSON.out.split_json.flatten().map{
        it -> [["id":"${it.baseName}".split('-')[-1]], it]
    }

    split_json.view()
    // and transform has both keys to match to everything toghether
    transform_json = INTERPRET_JSON.out.transform_json.flatten().map{
        it -> ["${it.baseName}".split('-')[-1], "${it.baseName}".split('-')[0..-3].join("-"), it]
    }

    transform_json.view()
    csv.view()

    // run split with json that only contains experiment name and split information. It runs only the necessary times, all unique ways to split + default split (random split) or column split (already present in data).
    SPLIT_CSV( split_json, csv )

    // assign to each splitted data the associated ransform information based on the split_transform_key generated in the interpret step.
    transform_split_tuple = transform_json.combine( SPLIT_CSV.out.split_data, by: 0 )

    // launch the actual noise subworkflow
    //TRANSFORM_CSV( transform_split_tuple )
    TRANSFORM_CSV( transform_json, csv )


    // unify transform output with interpret experiment json. so that each final data has his own fingerprint json that generated it + keyword. drop all other non relevant fields. it0 is the unique key matching transform Json and the experiment Json (fingerprint), it6 is the original filename of the input data given by the user.
    // it2 is the key used to match the splitted data with the correct transform Json (used later on by the analysis step to identify the models that have the same test set), it1 is the unique experimental config (the one containing all info for the given combination of split and transform and params values) it4  is the data csv transformed
    tmp = experiment_json.combine( TRANSFORM_CSV.out.transformed_data, by: 0 ).map{
        it -> ["${it[6].name} - ${it[0]}", it[2], it[1], it[4]]
    }

    // Launch the shuffle, (always happening on default) and disjointed from noise. Data are taken from the no-split option of split module. Which means that is either randomly splitted with default values or using the column present in the data.
    // It can be still skipped but by default is run. shuffle is set to true in nextflow.config
    data = tmp
    if ( params.shuffle ) {
        // take the data from the no-split process
        shuffle_correct_input = SPLIT_CSV.out.split_data.filter{
            it[0] == 'no_split'
        }
        SHUFFLE_CSV( shuffle_correct_input )
        // merge output of shuffle to the output of noise
        data = tmp.concat( SHUFFLE_CSV.out.shuffle_data )
    }


    emit:
    data

}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
