/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { STIMULUS_SPLIT_TRANSFORM } from '../../../modules/local/stimulus_split_transform.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SPLIT_DATA_CONFIG_TRANSFORM_WF {
    take:
    ch_data_config

    main:

    // separate the input channel into two channels
    // this is beacuse that split-transform module requires only meta and yaml (not csv)
    // we will merge the output of the split-transform module later with the csv channel
    ch_data_config.multiMap{ meta, yaml, csv_file -> 
        config: [meta, yaml]
        csv: [meta, csv_file]
    }.set{ ch_data_config }

    STIMULUS_SPLIT_TRANSFORM( ch_data_config.config )

    // transpose
    // and add transform_id to meta
    ch_yaml_sub_config = STIMULUS_SPLIT_TRANSFORM.out.sub_config
        .combine(ch_data_config.csv, by:0)
        .transpose()
        .map { meta,yaml,csv -> [ meta + [transform_id: yaml.baseName], yaml,csv] }

    emit:
    sub_config = ch_yaml_sub_config
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
