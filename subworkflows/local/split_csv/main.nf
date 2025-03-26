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
    ch_config_split

    main:

    // ==============================================================================
    // Split csv data using stimulus
    // ==============================================================================

    // combine each data with each split config
    ch_input = ch_data
        .combine(ch_config_split)
        .multiMap { meta_data, data, meta_config, config ->
            def meta = meta_data + [split_id: meta_config.split_id]
            data:
            [meta, data]
            config:
            [meta, config]
        }

    // run stimulus split
    STIMULUS_SPLIT_DATA(
        ch_input.data,
        ch_input.config
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
