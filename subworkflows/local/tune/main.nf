/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { STIMULUS_TUNE } from '../../../modules/local/stimulus/tune'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TUNE_WF {
    take:
    ch_transformed_data
    ch_yaml_sub_config
    ch_model
    ch_model_config
    ch_initial_weights

    main:

    ch_tune_input = ch_transformed_data
        .map { meta, data ->
            [[split_id: meta.split_id, transform_id: meta.transform_id], meta, data]
        }
        .combine(
            ch_yaml_sub_config.map { meta, config ->
                [[split_id: meta.split_id, transform_id: meta.transform_id], config]
            }
            ,by: 0
        )
        .combine(ch_model.map{it[1]})
        .combine(ch_model_config.map{it[1]})
        .combine(ch_initial_weights)    // when initial_weights is empty .map{it[1]} will return [], and not properly combined
        .multiMap { key, meta, data, data_config, model, model_config, meta_weights, initial_weights ->
            data:
                [meta, data, data_config]
            model:
                [meta, model, model_config, initial_weights]
        }

    STIMULUS_TUNE(
        ch_tune_input.data,
        ch_tune_input.model
    )

    emit:
    model = STIMULUS_TUNE.out.model
    optimizer = STIMULUS_TUNE.out.optimizer
    tune_experiments = STIMULUS_TUNE.out.artifacts
    journal = STIMULUS_TUNE.out.journal
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
