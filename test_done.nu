# test_done.nu — Tests for done.nu module

use done.nu

#[test]
def test_hooks_installed [] {
    let count = ($env.config.hooks.pre_prompt | default [] | length)
    assert ($count > 0) "hooks should be installed on use"
}

#[test]
def test_min_duration_config [] {
    assert ($env.DONE_MIN_DURATION | into int) == 5000
}

def main [] {
    print "=== done.nu test suite ==="
    print $"pre_prompt hooks: (($env.config.hooks.pre_prompt | default []) | length)"
    print $"DONE_MIN_DURATION: ($env.DONE_MIN_DURATION)"
    done status
    print ""
    done notify "Test" "done.nu test passed"
    print "=== done ==="
}
