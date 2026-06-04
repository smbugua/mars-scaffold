# ==========================================================================
# Reproducible Mars environment. Builds with network, runs with --network none.
# Bakes the target repo at its exact commit + all deps. Patches are NOT baked;
# they are applied at runtime by the platform (and by scripts/in_container_check.sh).
# ==========================================================================
FROM public.ecr.aws/d3j8x8q7/olympus-base:latest
# Fallback base if the above is unavailable:
# FROM public.ecr.aws/x8v8d7g8/mars-base:latest

ENV PYTHONHASHSEED=0 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_INPUT=1 \
    LC_ALL=C.UTF-8

WORKDIR /app

# Values come from challenge.env via --build-arg (see scripts/self_review.sh).
ARG REPO_URL
ARG COMMIT
ARG INSTALL_CMD="pip install -e ."

# Clone at the exact immutable commit (network available during build only).
RUN git clone "$REPO_URL" repo \
 && git -C repo checkout "$COMMIT" \
 && git -C repo config user.email mars@local \
 && git -C repo config user.name mars

# Install project + test deps so nothing needs the network at runtime.
RUN python -m pip install -U pip \
 && cd repo \
 && sh -c "$INSTALL_CMD" \
 && python -m pip install pytest

# Harness + config live outside the repo so `git clean` never touches them.
COPY test.sh challenge.env /app/
RUN chmod +x /app/test.sh

CMD ["/bin/bash"]
