
process STIMULUS_TRANSFORM_CSV {

    tag "${meta.id}-${meta2.id}"
    label 'process_medium'
    // TODO: push image to nf-core quay.io
    container "docker.io/mathysgrapotte/stimulus-py:0.2.6"

    input:
    tuple val(meta), path(data)
    tuple val(meta2), path(config)

    output:
    tuple val(meta), path("${prefix}.csv"), emit: transformed_data

    script:
    prefix = task.ext.prefix ?: "${meta.id}-${meta2.id}-trans"
    """
    stimulus-transform-csv \
        -c ${data} \
        -y ${config} \
        -o ${prefix}.csv
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}-${meta2.id}-trans"
    """
    touch ${prefix}.csv
    """
}
