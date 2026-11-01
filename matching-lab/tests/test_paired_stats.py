from matching_lab.paired_stats import bootstrap, wilcoxon


def test_exact_wilcoxon_handles_zeros_ties_and_signs():
    assert wilcoxon([0, 0]) == 1
    assert wilcoxon([1, 1, 1]) == 0.25
    assert wilcoxon([-1, -1, -1]) == 0.25
    assert wilcoxon([1, -1]) == 1


def test_bootstrap_is_reproducible_and_constant_for_constant_differences():
    assert bootstrap([2, 2, 2], 'fixed', seed=451, resamples=2000) == (2, 2)
    assert bootstrap([1, 2, 3], 'same', seed=451, resamples=2000) == bootstrap([1, 2, 3], 'same', seed=451, resamples=2000)
