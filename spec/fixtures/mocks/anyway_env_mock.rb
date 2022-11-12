mock_context "Anyway::Env" do
  let(:testo_env) do
    {
      "a" => "x",
      "data" => {
        "key" => "value"
      }
    }
  end

  before do
    env_double = instance_double("Anyway::Env")
    allow(::Anyway::Env).to receive(:new).and_return(env_double)

    allow(env_double).to receive(:fetch).with("UNKNOWN", any_args).and_return(Anyway::Env::Parsed.new({}, nil))
    allow(env_double).to receive(:fetch).with("TESTO", any_args).and_return(Anyway::Env::Parsed.new(testo_env, nil))
  end
end
