process STIMULUS_PREDICT {
    tag "${meta.id}"
    label 'process_medium'
    container "luisas/stimulus"

    input:
    tuple val(meta) , path(json_model), path(weigths)
    tuple val(meta2), path(data)

    output:
    tuple val(meta), path("${prefix}-pred"), emit: predictions
    path "versions.yml"          , emit: versions

    script:
    prefix = task.ext.prefix ?: meta.id
    def args = task.ext.args ?: ""
    """
    stimulus predict \
        -d ${data} \
        -m ${model} \
        -w ${weigths} \
        -o ${prefix}-pred \
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stimulus: \$(stimulus -v | cut -d ' ' -f 3)
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}-pred
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stimulus: \$(stimulus -v | cut -d ' ' -f 3)
    END_VERSIONS
    """
}
