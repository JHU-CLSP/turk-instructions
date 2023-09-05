eval = __import__('4_run_evaluation')
from evaluation.actions import MyActions
from evaluation.baselines import Baseline



def test_actions():
    baseline = Baseline()
    action_list = baseline.get_action_list()
    print(action_list)
    assert len(action_list) > 0, f"The action list should not be empty: {action_list}"

    encoded_actions_prompt = baseline.get_encoded_action_list()
    print(encoded_actions_prompt)
    assert len(encoded_actions_prompt) > 0, f"The encoded actions prompt should not be empty: {encoded_actions_prompt}"

def test_evaluation():
    evaluation = eval.Evaluation(solver="oracle", tasks="all",
                      do_eval=True, dump_features=False, report_field_stats=True)

    evaluation.enumerate_tasks(20)

if __name__ == "__main__":
    test_evaluation()
    test_actions()

    # TODO: test that we can apply the gold labels on the tasks

    # TODO: test the actions

    # TODO: test the evaluation
