process CUSTOM_MODIFY_MODEL_CONFIG {

    tag "${meta.id} - #trial ${n_trials}"
    label 'process_low'
    // TODO: push image to nf-core quay.io
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/ubuntu:22.04' :
    'nf-core/ubuntu:22.04' }"

    input:
    tuple val(meta), path(config)
    val(n_trials)

    output:
    tuple val(meta), path("${prefix}.yaml"), emit: config
    path "versions.yml"                    , emit: versions

    script:
    prefix = task.ext.prefix ?: "${config.baseName}-trials_updated"
    """
    # substitte the line containing n_trials in the config file with n_trials: \${n_trials}
    awk -v n_trials=${n_trials} '/n_trials: [0-9]+/ {gsub(/n_trials: [0-9]+/, "n_trials: " n_trials)}1' ${config} > ${prefix}.yaml

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.yaml

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS

    """
}
