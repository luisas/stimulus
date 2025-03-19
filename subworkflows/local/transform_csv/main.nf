/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { STIMULUS_TRANSFORM_CSV } from '../../../modules/local/stimulus/transform_csv'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TRANSFORM_CSV_WF {

    take:
    ch_split_data
    ch_sub_config

    main:
    // TODO add strategy for handling the launch of stimulus noiser as well as NF-core and other modules
    // TODO if the option is parellalization (for the above) then add csv column splitting  noising  merging

    // modify the meta for the combining
    ch_sub_config.map{
            meta, yaml -> [ [id: meta.id, split_id: meta.split_id], meta, yaml]
        }.set{ ch_sub_config }

    // ==============================================================================
    // Transform data using stimulus
    // ==============================================================================

    // combine all against all data vs configs
    ch_input = ch_split_data
        .combine(ch_sub_config, by: 0)
        .map{
            meta_split, csv, meta, yaml -> [meta, yaml, csv]
        }
        .multiMap{ meta, config, data ->
            data: [meta, data]
            config: [meta, config]
        }

    STIMULUS_TRANSFORM_CSV(
        ch_input.data,
        ch_input.config
    )
    ch_transformed_data = STIMULUS_TRANSFORM_CSV.out.transformed_data

    emit:
    transformed_data = ch_transformed_data
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
