/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { STIMULUS_SPLIT_DATA } from '../../../modules/local/stimulus/split_csv'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SPLIT_CSV_WF {

    take:
    ch_data
    ch_yaml_sub_config

    main:

    // ==============================================================================
    // Split csv data using stimulus
    // ==============================================================================

    // combine each data with each split yaml
    ch_input_for_splitting = ch_data
        .combine(ch_yaml_sub_config)
        .multiMap { meta_data, data, meta_yaml, yaml ->
            def meta = meta_data + [split_id: meta_yaml.split_id]
            data:
            [meta, data]
            config:
            [meta, yaml]
        }

    // run stimulus split
    STIMULUS_SPLIT_DATA(
        ch_input_for_splitting.data,
        ch_input_for_splitting.config
    )
    ch_split_data = STIMULUS_SPLIT_DATA.out.csv_with_split

    emit:
    split_data = ch_split_data
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
