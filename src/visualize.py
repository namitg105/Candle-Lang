"""
visualize.py
------------
Draws state-diagram images for an NFA or DFA so the automaton built for
a given pattern can actually be shown (not just claimed) in the review.
Uses networkx for graph layout + matplotlib for rendering (no graphviz
binary available in this environment).
"""

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import networkx as nx

from nfa import NFA


def draw_nfa(nfa: NFA, title: str, out_path: str):
    G = nx.MultiDiGraph()
    for s in range(nfa.num_states):
        G.add_node(s)
    edge_labels = {}
    for src, edges in nfa.transitions.items():
        for symbol, dst in edges:
            label = symbol if symbol is not None else "eps"
            key = G.add_edge(src, dst)
            edge_labels.setdefault((src, dst), []).append(label)

    pos = nx.spring_layout(G, seed=7, k=1.4)

    fig, ax = plt.subplots(figsize=(9, 6))
    node_colors = []
    for n in G.nodes():
        if n == nfa.start and n == nfa.accept:
            node_colors.append("#8e44ad")
        elif n == nfa.start:
            node_colors.append("#2ecc71")
        elif n == nfa.accept:
            node_colors.append("#e74c3c")
        else:
            node_colors.append("#aeb6bf")

    nx.draw_networkx_nodes(G, pos, node_color=node_colors, node_size=650, edgecolors="black", ax=ax)
    nx.draw_networkx_labels(G, pos, {n: f"q{n}" for n in G.nodes()}, font_size=9, ax=ax)
    nx.draw_networkx_edges(
        G, pos, connectionstyle="arc3,rad=0.15", arrowstyle="-|>", arrowsize=14, ax=ax,
        edge_color="#555555", node_size=650,
    )

    combined_labels = {k: ",".join(v) for k, v in edge_labels.items()}
    nx.draw_networkx_edge_labels(G, pos, edge_labels=combined_labels, font_size=8, ax=ax, label_pos=0.5)

    ax.set_title(f"{title}\n(green = start, red = accept, purple = both)")
    ax.axis("off")
    fig.tight_layout()
    fig.savefig(out_path, dpi=150)
    plt.close(fig)


def draw_dfa(dfa, title: str, out_path: str):
    G = nx.MultiDiGraph()
    for s in range(dfa.num_states):
        G.add_node(s)
    edge_labels = {}
    for src, trans in dfa.transitions.items():
        for symbol, dst in trans.items():
            G.add_edge(src, dst)
            edge_labels.setdefault((src, dst), []).append(symbol)

    pos = nx.spring_layout(G, seed=3, k=1.6)

    fig, ax = plt.subplots(figsize=(8, 5.5))
    node_colors = []
    for n in G.nodes():
        if n == dfa.start and n in dfa.accepts:
            node_colors.append("#8e44ad")
        elif n == dfa.start:
            node_colors.append("#2ecc71")
        elif n in dfa.accepts:
            node_colors.append("#e74c3c")
        else:
            node_colors.append("#aeb6bf")

    nx.draw_networkx_nodes(G, pos, node_color=node_colors, node_size=750, edgecolors="black", ax=ax)
    nx.draw_networkx_labels(G, pos, {n: f"q{n}" for n in G.nodes()}, font_size=10, ax=ax)
    nx.draw_networkx_edges(
        G, pos, connectionstyle="arc3,rad=0.15", arrowstyle="-|>", arrowsize=16, ax=ax,
        edge_color="#555555", node_size=750,
    )
    combined_labels = {k: ",".join(v) for k, v in edge_labels.items()}
    nx.draw_networkx_edge_labels(G, pos, edge_labels=combined_labels, font_size=9, ax=ax, label_pos=0.5)

    ax.set_title(f"{title}\n(green = start, red = accept, purple = both)")
    ax.axis("off")
    fig.tight_layout()
    fig.savefig(out_path, dpi=150)
    plt.close(fig)
