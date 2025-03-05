/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { softwareVersionsToYAML              } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText              } from '../subworkflows/local/utils_nfcore_deepmodeloptim_pipeline'
include { CHECK_MODEL_WF                      } from '../subworkflows/local/check_model'
include { PREPROCESS_IBIS_BEDFILE_TO_STIMULUS } from '../subworkflows/local/preprocess_ibis_bedfile_to_stimulus'
include { SPLIT_DATA_CONFIG_WF                } from '../subworkflows/local/split_data_config'
include { SPLIT_CSV_WF                        } from '../subworkflows/local/split_csv'
include { TRANSFORM_CSV_WF                    } from '../subworkflows/local/transform_csv'
include { TUNE_WF                             } from '../subworkflows/local/tune'

//
// MODULES: Consisting of nf-core/modules
//
include { CUSTOM_GETCHROMSIZES                } from '../modules/nf-core/custom/getchromsizes'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow DEEPMODELOPTIM {

    take:
    ch_data
    ch_data_config
    ch_model
    ch_model_config
    ch_initial_weights
    ch_preprocessing_config
    ch_genome

    main:

    // TODO collect all the versions files from the different processes
    ch_versions = Channel.empty()

    // ==============================================================================
    // preprocess data
    // ==============================================================================

    if (params.preprocessing_config) {

        // create genome index

        CUSTOM_GETCHROMSIZES(ch_genome)
        ch_genome_sizes = CUSTOM_GETCHROMSIZES.out.sizes

        // preprocess bedfile into stimulus format

        PREPROCESS_IBIS_BEDFILE_TO_STIMULUS(
            ch_data,
            ch_preprocessing_config.filter{it.protocol == 'ibis'},
            ch_genome,
            ch_genome_sizes
        )

        ch_data = PREPROCESS_IBIS_BEDFILE_TO_STIMULUS.out.data
    }

    // ==============================================================================
    // split meta yaml config file into individual yaml files
    // ==============================================================================

    SPLIT_DATA_CONFIG_WF( ch_data_config )
    ch_yaml_sub_config = SPLIT_DATA_CONFIG_WF.out.sub_config

    // ==============================================================================
    // split csv data file
    // ==============================================================================

    // NOTE for the moment, the previous step of yaml split is splitting the yaml file
    // into individual sub yaml files with all the fields.
    // The best would be to have a first step that splits into individual splitting-related
    // configs into individual splitting yaml files, and then a second step that splits the
    // transformation-related configs into individual transformation yaml files.
    // Then this pipeline will run m split configs x n transform configs times.
    //
    // Given this is not possible now, this implementation will only allow the user to
    // provide a yaml file that only contains one splitting way.
    // Here we take the first sub yaml for data splitting, since all sub configs contain
    // the same information about data splitting.
    //
    // TODO remove this when the above is implemented

    SPLIT_CSV_WF(
        ch_data,
        ch_yaml_sub_config.first()
    )
    ch_split_data = SPLIT_CSV_WF.out.split_data

    // ==============================================================================
    // transform csv file
    // ==============================================================================

    // TRANSFORM_CSV_WF(
    //     ch_split_data,
    //     ch_yaml_sub_config
    // )
    // ch_transformed_data = TRANSFORM_CSV_WF.out.transformed_data

    // // ==============================================================================
    // // Check model
    // // ==============================================================================

    // CHECK_MODEL_WF (
    //     ch_transformed_data.first(),
    //     ch_yaml_sub_config.first(),
    //     ch_model,
    //     ch_model_config,
    //     ch_initial_weights
    // )

    // // ==============================================================================
    // // Tune model
    // // ==============================================================================

    // TUNE_WF(
    //     ch_transformed_data,
    //     ch_yaml_sub_config,
    //     ch_model,
    //     ch_model_config,
    //     ch_initial_weights
    // )

    /*
    // Software versions collation remains as comments
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  + 'pipeline_software_' +  ''  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions = ch_versions  // channel: [ path(versions.yml) ]
    */

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
