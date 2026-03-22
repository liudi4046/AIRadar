"""Insert a few demo posts so the Timeline tab is not empty (MVP preview).

Run after seed_entities.py. Safe to re-run: uses fixed ids (upsert).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv

load_dotenv()

from src.db import get_supabase

DEMO_POSTS = [
    {
        "id": "demo-post-karpathy-01",
        "entity_id": "andrej-karpathy",
        "source_type": "twitter",
        "source_url": "https://x.com/karpathy/status/example",
        "original_text": "LLMs keep getting better at reasoning with less prompt engineering. The future is model quality, not prompt tricks.",
        "summary_zh": "Karpathy：大模型推理越来越强，未来靠模型本身而非 Prompt 技巧。",
        "insight_zh": "若观点成立，会削弱「Prompt 工程」作为核心竞争力的叙事，影响工具链与培训市场。",
        "interpretation_zh": "这条动态强调能力曲线正在从「教用户怎么写 Prompt」转向「模型自己把事情做对」。对开发者意味着更少模板化技巧、更多关注任务拆解与评测；对产品则更接近「说人话就能用」的体验。",
        "published_at": "2026-03-21T08:30:00+00:00",
        "is_trending": False,
        "trending_source": "",
    },
    {
        "id": "demo-post-openai-01",
        "entity_id": "openai",
        "source_type": "rss",
        "source_url": "https://openai.com/blog/example",
        "original_text": "We're shipping updates to make API responses faster and more predictable for production workloads.",
        "summary_zh": "OpenAI：API 响应将更快、更稳定，面向生产负载优化。",
        "insight_zh": "企业集成与延迟敏感场景会直接受益，可能推动更多实时应用落地。",
        "interpretation_zh": "对国内用户而言，若通过合规渠道调用，延迟与稳定性往往是比「模型有多聪明」更先碰到的瓶颈。此类更新属于基础设施层改进，利于把 Demo 做成可上线的服务。",
        "published_at": "2026-03-21T06:00:00+00:00",
        "is_trending": True,
        "trending_source": "演示数据 · AI 热点",
    },
    {
        "id": "demo-post-sama-01",
        "entity_id": "sam-altman",
        "source_type": "twitter",
        "source_url": "https://x.com/sama/status/example",
        "original_text": "The next wave of AI products will be judged by real economic value created, not demo videos.",
        "summary_zh": "Sam Altman：下一波 AI 产品要看创造的真实经济价值，而非演示视频。",
        "insight_zh": "信号是行业从「秀能力」转向「可度量产出」，投融资与采购都会更挑剔。",
        "interpretation_zh": "对创业者和团队来说，意味着要更早想清楚计费单位、留存与成本结构；对使用者来说，噱头型功能会降温，能省时间或省钱的工具更容易活下来。",
        "published_at": "2026-03-20T14:15:00+00:00",
        "is_trending": False,
        "trending_source": "",
    },
    {
        "id": "demo-post-anthropic-01",
        "entity_id": "anthropic",
        "source_type": "rss",
        "source_url": "https://www.anthropic.com/news/example",
        "original_text": "New research on scalable oversight and safer deployment patterns for large language models.",
        "summary_zh": "Anthropic：发布关于大模型可扩展监督与安全部署的新研究。",
        "insight_zh": "合规与政企客户会更关注「可审计、可约束」的模型行为，安全叙事继续升温。",
        "interpretation_zh": "这类更新往往偏研究向，但会逐步沉淀为产品里的护栏、日志与策略接口。如果你在做 toB 或金融场景，值得跟踪其方法论是否可映射到自己的风控流程。",
        "published_at": "2026-03-19T11:00:00+00:00",
        "is_trending": False,
        "trending_source": "",
    },
    {
        "id": "demo-post-hf-01",
        "entity_id": "huggingface",
        "source_type": "rss",
        "source_url": "https://huggingface.co/blog/example",
        "original_text": "Community highlights: fine-tuning recipes, quantization guides, and new leaderboards.",
        "summary_zh": "Hugging Face：社区精选：微调配方、量化教程与新榜单。",
        "insight_zh": "开源生态继续降低「从论文到可跑代码」的门槛，小团队也能跟上大模型迭代。",
        "interpretation_zh": "若你主要用国内模型，仍可把 HF 当作数据集、评测与训练脚本的参考源；很多技巧（LoRA、QLoRA、评测集）是模型无关的。",
        "published_at": "2026-03-18T09:45:00+00:00",
        "is_trending": False,
        "trending_source": "",
    },
]


def seed():
    client = get_supabase()
    for post in DEMO_POSTS:
        client.table("posts").upsert(post).execute()
        print(f"  Seeded post: {post['id']}")
    print(f"\nDone. {len(DEMO_POSTS)} demo posts (upsert).")


if __name__ == "__main__":
    seed()
