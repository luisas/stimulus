/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { STIMULUS_PREDICT             } from '../../../modules/local/stimulus/predict'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow EVALUATION_WF {
    take:
    ch_json_model
    ch_weights
    ch_data

    main:

    ch_versions = Channel.empty()

    // 
    // Evaluation mode 1: Predict the data using the best model 
    // and then compare the predictions of 2 different models
    //

    STIMULUS_PREDICT(
        ch_json_model,
        ch_weights,
        ch_data
    )
    ch_versions = ch_versions.mix(STIMULUS_PREDICT.out.versions)
    predictions = STIMULUS_PREDICT.out.predictions
    predictions.view()



    emit: 
    versions = ch_versions // channel: [ versions.yml ]

}