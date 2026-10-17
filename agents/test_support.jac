import from jaclang.byllm.lib { MockLLM }


def build_mock_llm(outputs: list) -> MockLLM {
    return MockLLM(
        model_name="mockllm",
        config={"outputs": outputs}
    );
}
