class Crn < Formula
  desc "Job scheduler per directory"
  homepage "https://github.com/TYRONEMICHAEL/crn"
  head "https://github.com/TYRONEMICHAEL/crn.git", branch: "main"

  # go.mod: go 1.25; pure-Go deps (cobra, ncruces/go-sqlite3 via wazero), no cgo
  depends_on "go" => :build

  def install
    # make build: go build -o crn ./cmd/crn/
    system "go", "build", "-o", "crn", "./cmd/crn/"
    bin.install "crn"

    # replaces: crn completion zsh > ~/.oh-my-zsh/custom/completions/_crn
    generate_completions_from_executable(bin/"crn", "completion")
  end
end