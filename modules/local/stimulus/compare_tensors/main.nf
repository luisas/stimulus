process STIMULUS_COMPARE_TENSORS {
    tag "${meta.id}"
    label 'process_medium'
    container "docker.io/mathysgrapotte/stimulus-py:dev"

    input:
    tuple val(meta), path(tensors)

    output:
    tuple val(meta), path("${prefix}.csv"), emit: csv
    path "versions.yml"          , emit: versions

    script:
    prefix = task.ext.prefix ?: meta.id
    def args = task.ext.args ?: ""
    def header = meta.keySet().join(",")
    def values = meta.values().join(",")
    """
    stimulus compare-tensors \
        -t ${tensors} \
        ${args} >> scores.txt

    # Extract first row of scores.txt
    header_scores=\$(head -n 1 scores.txt)

    # Add metadata info to output file
    echo "${header},\$header_scores" > "${prefix}.scores"

    # Add values
    scores=\$(awk '{sub(/[[:space:]]+\$/, "")} 1' scores.txt | tr -s '[:blank:]' ',')
    echo "${values},\$scores" >> "${prefix}.scores"

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
