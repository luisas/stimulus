/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { STIMULUS_TUNE              } from '../../../modules/local/stimulus/tune'
include { CUSTOM_MODIFY_MODEL_CONFIG } from '../../../modules/local/custom/modify_model_config'

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
    tune_replicates

    main:

    // Split the tune_trials_range into individual trials
    ch_versions = Channel.empty()


    // Modify the model config file to include the number of trials
    // This allows us to run multiple trials numbers with the same model
    CUSTOM_MODIFY_MODEL_CONFIG(
        ch_model_config.collect(),
        tune_trials_range
    )
    ch_versions = ch_versions.mix(CUSTOM_MODIFY_MODEL_CONFIG.out.versions)
    ch_model_config = CUSTOM_MODIFY_MODEL_CONFIG.out.config


    ch_tune_input = ch_transformed_data
        .join(ch_yaml_sub_config)
        .combine(ch_model)
        .combine(ch_model_config)
        .combine(ch_initial_weights)
        .combine(tune_replicates)
        .multiMap { meta, data, data_config, meta_model, model, meta_model_config, model_config, meta_weights, initial_weights, n_replicate ->
            data_and_config:
                [meta+[replicate: n_replicate], data, data_config]
            model_and_config:
                [meta_model+[replicate: n_replicate], model, model_config, initial_weights]
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
