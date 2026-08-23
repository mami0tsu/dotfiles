#!/usr/bin/env python3
import argparse


def decide(
    *,
    current_content_sha256: str,
    expected_pre_content_sha256: str,
    desired_content_sha256: str,
) -> str:
    if current_content_sha256 == desired_content_sha256:
        return "complete"
    if current_content_sha256 == expected_pre_content_sha256:
        return "write"
    return "stop"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--current-content-sha256", required=True)
    parser.add_argument("--expected-pre-content-sha256", required=True)
    parser.add_argument("--desired-content-sha256", required=True)
    args = parser.parse_args()
    print(
        decide(
            current_content_sha256=args.current_content_sha256,
            expected_pre_content_sha256=args.expected_pre_content_sha256,
            desired_content_sha256=args.desired_content_sha256,
        )
    )


if __name__ == "__main__":
    main()
