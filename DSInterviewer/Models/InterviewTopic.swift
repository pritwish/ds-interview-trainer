import Foundation

enum InterviewTopic: String, Codable, CaseIterable, Identifiable {
    case mlSystemDesign = "ML System Design"
    case statisticsAndExperimentation = "Statistics & Experimentation"
    case deepLearning = "Deep Learning"
    case nlp = "NLP & LLMs"
    case recommendationSystems = "Recommendation Systems"
    case causalInference = "Causal Inference"
    case mlOps = "MLOps & Production ML"
    case featureEngineering = "Feature Engineering"
    case timeSeriesForecasting = "Time Series & Forecasting"
    case computerVision = "Computer Vision"
    case reinforcementLearning = "Reinforcement Learning"
    case dataStrategyLeadership = "Data Strategy & Leadership"
    case fullLoop = "Full-Loop Interview"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .mlSystemDesign: return "cpu"
        case .statisticsAndExperimentation: return "chart.bar.xaxis"
        case .deepLearning: return "brain"
        case .nlp: return "text.bubble"
        case .recommendationSystems: return "star.leadinghalf.filled"
        case .causalInference: return "arrow.triangle.branch"
        case .mlOps: return "gearshape.2"
        case .featureEngineering: return "wrench.and.screwdriver"
        case .timeSeriesForecasting: return "chart.xyaxis.line"
        case .computerVision: return "eye"
        case .reinforcementLearning: return "gamecontroller"
        case .dataStrategyLeadership: return "person.3"
        case .fullLoop: return "arrow.3.trianglepath"
        }
    }

    var description: String {
        switch self {
        case .mlSystemDesign:
            return "End-to-end ML system design: serving infrastructure, feature stores, model registries, A/B testing platforms, and scaling to billions of predictions."
        case .statisticsAndExperimentation:
            return "Hypothesis testing, power analysis, multi-armed bandits, variance reduction, interference effects, and long-term holdout design."
        case .deepLearning:
            return "Architecture design, optimization theory, regularization, distributed training, mixed precision, and custom layer implementation."
        case .nlp:
            return "Transformer internals, pre-training strategies, RLHF, prompt engineering at scale, retrieval-augmented generation, and tokenizer design."
        case .recommendationSystems:
            return "Collaborative filtering at scale, two-tower models, sequence-based recommendations, cold start, and real-time personalization."
        case .causalInference:
            return "Instrumental variables, difference-in-differences, regression discontinuity, synthetic controls, and double ML."
        case .mlOps:
            return "CI/CD for ML, model monitoring, data drift detection, feature stores, model versioning, and incident response."
        case .featureEngineering:
            return "Feature crosses, embedding strategies, temporal features, automated feature selection, and feature store architecture."
        case .timeSeriesForecasting:
            return "ARIMA family, Prophet, neural forecasting, hierarchical time series, changepoint detection, and anomaly detection."
        case .computerVision:
            return "ConvNet architectures, object detection, segmentation, vision transformers, self-supervised learning, and edge deployment."
        case .reinforcementLearning:
            return "Policy gradient methods, actor-critic, multi-agent RL, offline RL, reward shaping, and sim-to-real transfer."
        case .dataStrategyLeadership:
            return "Building data science teams, roadmap setting, stakeholder management, technical vision, and org-wide data culture."
        case .fullLoop:
            return "A comprehensive interview covering ML fundamentals, system design, coding, behavioral, and leadership—simulating a real big-tech on-site."
        }
    }

    var topicPromptContext: String {
        switch self {
        case .mlSystemDesign:
            return """
            Focus on ML System Design. Ask about designing end-to-end ML systems similar to those at Google, Meta, Netflix, or Apple. \
            Cover: model serving at scale (millions of QPS), feature store design (Feast, Tecton-style), \
            training pipelines (distributed training orchestration), model registry and versioning, \
            online/offline feature consistency, A/B testing infrastructure, shadow deployments, \
            canary releases for models, latency budgets, and cost optimization. \
            Probe for experience with specific infra: Kubernetes, Ray, TFX, Kubeflow, MLflow. \
            Ask about tradeoffs between batch and real-time serving.
            """
        case .statisticsAndExperimentation:
            return """
            Focus on Statistics & Experimentation. Probe deeply on: CUPED and variance reduction techniques, \
            network interference and switchback designs, multi-armed bandits (Thompson Sampling, UCB, contextual), \
            sequential testing and always-valid p-values, power analysis for complex metrics, \
            ratio metrics and delta method, bootstrap methods, Bayesian A/B testing, \
            long-term holdout experiments, metric decomposition, and guardrail metrics. \
            Ask about real scenarios: "How would you detect if an experiment is polluted by network effects?" \
            Challenge any hand-wavy answers with mathematical rigor.
            """
        case .deepLearning:
            return """
            Focus on Deep Learning at a research-engineer level. Ask about: gradient flow and vanishing/exploding gradients \
            in deep networks, batch norm vs layer norm vs group norm tradeoffs, attention mechanism mathematics, \
            mixed-precision training (FP16/BF16), distributed training strategies (data parallel, model parallel, pipeline parallel), \
            custom loss function design, learning rate scheduling (cosine, warmup, cyclical), \
            architecture search (NAS), knowledge distillation, pruning and quantization for deployment. \
            Expect candidates to derive backpropagation for custom layers on the spot.
            """
        case .nlp:
            return """
            Focus on NLP & LLMs. Cover: Transformer architecture from scratch (multi-head attention, positional encoding), \
            pre-training objectives (MLM, CLM, span corruption), RLHF pipeline (reward modeling, PPO), \
            DPO vs RLHF tradeoffs, retrieval-augmented generation architecture, \
            tokenizer design (BPE, SentencePiece, Unigram), prompt engineering at production scale, \
            context window optimization, KV-cache optimization, speculative decoding, \
            model parallelism for serving large models, fine-tuning strategies (LoRA, QLoRA, full fine-tune), \
            evaluation methodologies for LLMs. Challenge on scaling laws and chinchilla-optimal training.
            """
        case .recommendationSystems:
            return """
            Focus on Recommendation Systems at scale. Cover: two-tower architecture (query and item towers), \
            negative sampling strategies, retrieval vs ranking pipeline, \
            multi-task learning for recommendations (watch time, clicks, engagement), \
            sequential recommendation models, session-based recommendations, \
            cold start strategies, explore-exploit tradeoffs, real-time personalization, \
            embedding table design and management, feature interaction networks (DCN, DeepFM), \
            calibration of recommendation scores, diversity and fairness in recommendations.
            """
        case .causalInference:
            return """
            Focus on Causal Inference methods. Cover: potential outcomes framework, \
            instrumental variables and weak instrument problems, difference-in-differences with staggered adoption, \
            regression discontinuity (sharp and fuzzy), synthetic control methods, \
            double/debiased ML, meta-learners (S-learner, T-learner, X-learner), \
            heterogeneous treatment effects, sensitivity analysis (Rosenbaum bounds), \
            propensity score methods and their pitfalls, DAGs and structural causal models, \
            interference and spillover effects, mediation analysis. \
            Ask candidates to identify violations of assumptions in realistic scenarios.
            """
        case .mlOps:
            return """
            Focus on MLOps & Production ML. Cover: CI/CD pipelines for ML (model testing, data validation), \
            model monitoring (data drift, concept drift, prediction drift), \
            feature store architecture (online/offline stores, feature freshness), \
            model versioning and lineage tracking, incident response for model failures, \
            A/B testing infrastructure, shadow mode deployment, model rollback strategies, \
            cost optimization (GPU utilization, spot instances), data pipeline orchestration (Airflow, Dagster), \
            reproducibility and experiment tracking, model governance and compliance. \
            Probe for war stories about production ML failures.
            """
        case .featureEngineering:
            return """
            Focus on Feature Engineering at scale. Cover: temporal feature engineering (lag features, rolling windows, \
            time-since features), embedding strategies for categorical variables, \
            feature crosses and polynomial features at scale, automated feature selection \
            (mutual information, permutation importance, LASSO), feature store architecture, \
            handling high-cardinality categoricals, target encoding and its pitfalls, \
            feature freshness and staleness, privacy-preserving features, \
            text feature extraction at scale, graph-based features.
            """
        case .timeSeriesForecasting:
            return """
            Focus on Time Series & Forecasting. Cover: ARIMA/SARIMA model selection and diagnostics, \
            state space models, Prophet internals and limitations, neural forecasting (N-BEATS, TFT, DeepAR), \
            hierarchical time series reconciliation, changepoint detection algorithms, \
            anomaly detection in time series, cross-validation for time series (expanding window, sliding window), \
            probabilistic forecasting and prediction intervals, multi-step forecasting strategies, \
            covariate handling, seasonality decomposition (STL).
            """
        case .computerVision:
            return """
            Focus on Computer Vision. Cover: CNN architecture evolution (ResNet, EfficientNet, ConvNeXt), \
            object detection frameworks (YOLO family, DETR), instance and semantic segmentation, \
            Vision Transformers (ViT, DeiT, Swin), self-supervised learning (DINO, MAE, SimCLR), \
            3D vision and depth estimation, edge deployment and model optimization, \
            data augmentation strategies, few-shot learning, domain adaptation, \
            video understanding models, multi-modal vision-language models.
            """
        case .reinforcementLearning:
            return """
            Focus on Reinforcement Learning. Cover: policy gradient methods (REINFORCE, PPO, TRPO), \
            actor-critic architectures (A2C, A3C, SAC), model-based RL, \
            multi-agent RL and emergent behaviors, offline RL (CQL, IQL), \
            reward shaping and sparse reward problems, exploration strategies, \
            sim-to-real transfer, safe RL and constrained optimization, \
            RL for recommendation and ranking, bandit algorithms at scale.
            """
        case .dataStrategyLeadership:
            return """
            Focus on Data Strategy & Technical Leadership. Cover: building and scaling data science teams, \
            technical roadmap creation, stakeholder management and communicating uncertainty, \
            data-informed product strategy, setting org-wide experimentation culture, \
            hiring and mentoring senior data scientists, managing technical debt in ML systems, \
            build vs buy decisions for ML infrastructure, cross-functional leadership with engineering and product, \
            data governance and privacy strategy, democratizing data access, \
            managing competing priorities across teams.
            """
        case .fullLoop:
            return """
            Conduct a full-loop interview simulating a big-tech on-site. Cover ALL of these rounds in sequence: \
            1) Technical Screen: ML fundamentals and coding \
            2) ML System Design: End-to-end system design \
            3) Applied ML: Real-world problem solving with ML \
            4) Statistics & Experimentation: Deep statistical reasoning \
            5) Behavioral & Leadership: Leadership principles and conflict resolution \
            Transition between rounds explicitly. Each round should have 3-5 questions. \
            Assess overall hire/no-hire at the end with detailed rubric.
            """
        }
    }
}
