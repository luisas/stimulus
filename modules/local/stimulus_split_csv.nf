
process STIMULUS_SPLIT_DATA {

    tag "${meta.id}-${meta2.id}"
    label 'process_low'
    // TODO: push image to nf-core quay.io
    container "docker.io/mathysgrapotte/stimulus-py:0.2.6"

    input:
    tuple val(meta), path(data)
    tuple val(meta2), path(sub_config)

    output:
    tuple val(meta), path("${prefix}.csv"), emit: csv_with_split

    script:
    prefix = task.ext.prefix ?: "${meta.id}-split-${meta2.id}"
    """
    stimulus-split-csv \
        -c ${data} \
        -y ${sub_config} \
        -o ${prefix}.csv
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}-split-${meta2.id}"
    """
    touch ${prefix}.csv
    """
}
