# Brainstorming Session Results

**Session Date:** 2025-11-19
**Facilitator:** BMAD Master (BMad)
**Participant:** BMad

## Session Start

Session Topic: Product requirements (PRD) improvements
Session Goals: Define clear steps to improve the PRD and produce actionable tasks for MVP submission.

**Session Start Plan:**
- Use the provided project description as the primary context.
- Follow an AI-recommended approach to select 3-5 facilitation techniques suited for PRD improvement.
- Use techniques to identify missing or unclear PRD sections, uncover assumptions, and establish concrete next steps for development, testing, and submission.
- Document all ideas and prioritize top 3 actions into the final PRD.

---

## Executive Summary (initial)
- Topic: PRD improvements for the DSAI4205 Sentiment Analysis Group Project.
- Session Goals: Create a clear step-by-step plan to finalize the PRD and to define modeling experiments, deliverables, and roles to meet the Nov 23 deadline.
- Techniques Planned: Role Playing (Stakeholder), SCAMPER, Mind Mapping, Assumption Reversal, Question Storming.

---

## Techniques Recommended by AI (3-5 recommended)
1. Role Playing (collaborative) — 15-20 min
   - Why: Map stakeholder needs and acceptance criteria. Clarifies who each PRD section must satisfy.
   - Outcome: Clear, stakeholder-driven acceptance criteria for each PRD section.
2. SCAMPER Method (structured) — 15-20 min
   - Why: Systematically improve PRD sections (features, constraints, non-functional requirements).
   - Outcome: Concrete revisions for each PRD section and specific feature/requirement edits.
3. Mind Mapping (structured) — 10-15 min
   - Why: Visually break down PRD sections into tasks and steps to create an ordered, actionable plan.
   - Outcome: A step-by-step action plan with owners and estimated time per item.
4. Assumption Reversal (deep) — 10-15 min
   - Why: Surface and test PRD's hidden assumptions (dataset availability, metric assumptions, resources) and reframe them.
   - Outcome: Identified assumptions to keep or adjust and contingency steps.
5. Question Storming (deep) — 10-15 min
   - Why: Ensure the PRD answers the right questions — clarifies scope, success metrics, constraints, roles.
   - Outcome: A prioritized list of PRD clarifying questions and resolved answers.

---

## Next Step
---

Options: [a] Advanced Elicitation, [c] Continue, [p] Party-Mode, [y] YOLO the rest of this workflow.

---

## Technique Session — Role Playing (Executed)

Participants simulated:
- Product Owner / PM (Name1)
- Data Engineer (Name2)
- Architect / Model Lead (architech)
- ML Engineer (Name3)
- Analyst (Name4)
- QA/Reviewer (Name5)

### Role-Playing Transcript (abridged)

Name1 (Product Owner / PM): "We need a PRD that's crystal-clear for grading; my priority is a concise acceptance criteria (Notebook runs end-to-end, 2-page report, and slides). Let's keep the macro-F1 metric as canonical. Please list model owners and ensure the final deck showcases the best model and the top 3 recommended actions."

Name2 (Data Engineer): "I'll validate the dataset and confirm the path — currently unspecified. Priority: create a reproducible data pipeline, log the random seeds, and check class balance. I'll start by loading the dataset and producing a 'data_overview.ipynb'."

architech (Architect / Model Lead): "We should try TF-IDF baseline plus a LightGBM tuning, and BERT fine-tuning for final model. For BERT, we should set epoch caps and fallback to pretrained embeddings if compute becomes tight. We'll use GPU for BERT; if not available, we'll rely on embeddings extraction via sentence-transformers."

Name3 (ML Engineer): "I'll own the traditional models and the ensemble. Plan: implement baseline logistic regression, RandomForest, LightGBM and XGBoost, then evaluate stacking/ensembling. Will run GridSearchCV where lightweight, and tune XGBoost using randomized search and early stopping. I'll ensure reproducible splits using the specified split from dataset."

Name4 (Analyst): "I'll create required visualizations: class distribution, word frequency, word cloud, confusion matrix, and precision-recall curves. I will also prepare slides that show the one-page story and top 3 insights."

Name5 (QA/Reviewer): "I will run tests to ensure the Notebook reproduces exactly: documented seed, requirements.txt, and provide simple 'run.sh' for reviewers. I will also confirm that the dataset split is unchanged across runs."

### Decisions & Agreements
- Confirm metric: **macro-F1** (canonical acceptance metric)
- Dataset path: must be provided by team (placeholder: `unspecified`). Data Engineer (Name2) will confirm and set `data/dataset.csv` or similar.
- Compute: GPU available; BERT fine-tuning permitted with capped epochs and early stopping.
- Acceptance Criteria and Evaluation Checklist (noted in PRD): enforced.
- Ownership: model responsibilities auto-assigned in PRD.

### Identified PRD Improvements (actionable)
1. Add explicit `dataset_path` field and required dataset loading instructions in a `DATA.md` (Name2).  
2. Include a reproducibility section with environment details, seed numbers, and a `requirements.txt` (Name5).  
3. Provide a fallback plan for BERT: precomputed embedding extraction if GPU is unavailable (architech).  
4. Add a short “How to evaluate” quick reference card in the Notebook summarizing how to compute macro-F1 and reproduce test results (Name3 & Name4).  
5. Clarify visualization owners and plot templates in `report-assets/` folder (Name4).

### Next actions
- Name2: Confirm dataset path, upload to repo/drive, create `DATA.md` with sample preview — due: Nov 20 (EOD)  
- Name3: Implement baseline logistic regression + TF-IDF pipeline and other classic models scaffolding — due: Nov 20 (EOD)  
- architech: Prepare BERT fine-tuning plan and fallback to sentence-transformer embedding strategy — due: Nov 21  
- Name4: Create 5 visualization templates and provide sample outputs — due: Nov 21  
- Name5: Create reproducibility checklist, `requirements.txt`, and run tests — due: Nov 22  

---

**Session Note:** This Role Playing session generated concrete PRD clarifications and an action plan; next step is to create the tasks file and scaffold the Notebook.

Please select an option (a/c/p/y) and/or the technique number to begin (1-5).