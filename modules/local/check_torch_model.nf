
process CHECK_TORCH_MODEL {

    tag "$experiment_name-$original_csv"
    label 'process_medium'
    container "alessiovignoli3/stimulus:latest"
    
    input:
    tuple path(original_csv), path(model),  path(experiment_config), path(ray_tune_config)

    output:
    stdout emit: standardout

    script:
    """
    launch_check_model.py -d ${original_csv} -m ${model} -e ${experiment_config} -c ${ray_tune_config}
    """

    stub:
    """
    echo bubba
    """
}
