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
    tune_trials_range

    main:

    // Split the tune_trials_range into individual trials
    ch_versions = Channel.empty()

    tune_trials_range.view()

    ch_model_config.view()



    ch_tune_input = ch_transformed_data
        .join(ch_yaml_sub_config)
        .combine(ch_model)
        .combine(ch_model_config)
        .combine(ch_initial_weights)
        .multiMap { meta, data, data_config, meta_model, model, meta_model_config, model_config, meta_weights, initial_weights ->
            data_and_config:
                [meta, data, data_config]
            model_and_config:
                [meta_model, model, model_config, initial_weights]
        }

    STIMULUS_TUNE(
        ch_tune_input.data_and_config,
        ch_tune_input.model_and_config
    )
    ch_versions = ch_versions.mix(STIMULUS_TUNE.out.versions)

    emit:
    model = STIMULUS_TUNE.out.model
    optimizer = STIMULUS_TUNE.out.optimizer
    tune_experiments = STIMULUS_TUNE.out.tune_experiments
    versions = ch_versions // channel: [ versions.yml ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
