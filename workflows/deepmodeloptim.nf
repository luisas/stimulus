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
include { SPLIT_DATA_CONFIG_SPLIT_WF          } from '../subworkflows/local/split_data_config_split'
include { SPLIT_DATA_CONFIG_TRANSFORM_WF      } from '../subworkflows/local/split_data_config_transform'
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
    // split meta yaml split config file into individual yaml files
    // ==============================================================================

    SPLIT_DATA_CONFIG_SPLIT_WF( ch_data_config )
    ch_yaml_sub_config_split = SPLIT_DATA_CONFIG_SPLIT_WF.out.sub_config

    // ==============================================================================
    // split csv data file
    // ==============================================================================

    SPLIT_CSV_WF(
        ch_data,
        ch_yaml_sub_config_split
    )
    ch_split_data = SPLIT_CSV_WF.out.split_data

    ch_split_data.view{"ch_split_data is $it"}

    // ==============================================================================
    // split meta yaml transform config file into individual yaml files
    // ==============================================================================

    SPLIT_DATA_CONFIG_TRANSFORM_WF( ch_yaml_sub_config_split )
    ch_yaml_sub_config = SPLIT_DATA_CONFIG_TRANSFORM_WF.out.sub_config

    // ==============================================================================
    // transform csv file
    // ==============================================================================

    TRANSFORM_CSV_WF(
        ch_split_data,
        ch_yaml_sub_config
    )
    ch_transformed_data = TRANSFORM_CSV_WF.out.transformed_data

    ch_transformed_data.view{"ch_transformed_data is $it"}

    // ==============================================================================
    // Check model
    // ==============================================================================

    CHECK_MODEL_WF (
        ch_transformed_data.first(),
        ch_yaml_sub_config.first(),
        ch_model,
        ch_model_config,
        ch_initial_weights
    )

    // ==============================================================================
    // Tune model
    // ==============================================================================

    TUNE_WF(
        ch_transformed_data,
        ch_yaml_sub_config,
        ch_model,
        ch_model_config,
        ch_initial_weights
    )

    // Software versions collation remains as comments
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'deepmodeloptim_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions = ch_versions  // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
