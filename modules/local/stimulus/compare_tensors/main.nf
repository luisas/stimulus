process STIMULUS_COMPARE_TENSORS {
    tag "${meta.id}"
    label 'process_medium'
    container "docker.io/mathysgrapotte/stimulus-py:dev"

    input:
    tuple val(meta) , path(tensor1)
    tuple val(meta2), path(tensor2)

    output:
    tuple val(meta), path("${prefix}.csv"), emit: csv
    path "versions.yml"          , emit: versions

    script:
    prefix = task.ext.prefix ?: meta.id
    def args = task.ext.args ?: ""
    """
    stimulus compare_tensors \
        -t1 ${tensor1} \
        -t2 ${tensor2} \
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stimulus: \$(stimulus -v | cut -d ' ' -f 3)
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: meta.id
    """
    touch ${prefix}.csv
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stimulus: \$(stimulus -v | cut -d ' ' -f 3)
    END_VERSIONS
    """
}
