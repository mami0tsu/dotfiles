import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("resume_decision.py")
SPEC = importlib.util.spec_from_file_location("resume_decision", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class ResumeDecisionTest(unittest.TestCase):
    def test_completed_write_is_not_repeated(self) -> None:
        self.assertEqual(
            "complete",
            MODULE.decide(
                current_content_sha256="desired",
                expected_pre_content_sha256="old",
                desired_content_sha256="desired",
            ),
        )

    def test_unchanged_pre_state_can_be_written(self) -> None:
        self.assertEqual(
            "write",
            MODULE.decide(
                current_content_sha256="old",
                expected_pre_content_sha256="old",
                desired_content_sha256="desired",
            ),
        )

    def test_changed_content_stops(self) -> None:
        self.assertEqual(
            "stop",
            MODULE.decide(
                current_content_sha256="other",
                expected_pre_content_sha256="old",
                desired_content_sha256="desired",
            ),
        )


if __name__ == "__main__":
    unittest.main()
