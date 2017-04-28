def test_for_no_group(Group):
    assert Group("nogroup").exists
    
def test_for_dcos_bootstrap_user(User):
    assert User("dcos-bootstrap").exists