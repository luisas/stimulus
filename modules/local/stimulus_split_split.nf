
process SSTIMULUS_SPLIT_SPLIT {

    tag "$meta.id"
    label 'process_low'
    // TODO: push image to nf-core quay.io
    container "docker.io/mathysgrapotte/stimulus-py:0.3.0.dev"

    input:
    tuple val(meta), path(data_config)

    output:
    tuple val(meta), path ("*.yaml"), emit: sub_config

    script:
    """
    stimulus split-split -y ${data_config}
    """

    stub:
    """
    touch test_0.yaml
    touch test_1.yaml
    touch test_2.yaml
    """
}
