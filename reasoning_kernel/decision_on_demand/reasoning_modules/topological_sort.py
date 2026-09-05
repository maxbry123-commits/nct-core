from __future__ import annotations

from collections.abc import Hashable, Iterable, Mapping
from typing import TypeVar

import networkx as nx

Node = TypeVar("Node", bound=Hashable)


def topological_sort(dependencies: Mapping[Node, Iterable[Node]]) -> list[Node]:
    """Return a deterministic topological order for a dependency mapping.

    The mapping is ``node -> prerequisites``.  A directed edge is created
    from each prerequisite to the node that depends on it.  Cycles are
    rejected explicitly instead of returning a partial order.
    """
    graph = nx.DiGraph()
    for node, prerequisites in dependencies.items():
        graph.add_node(node)
        for prerequisite in prerequisites:
            graph.add_edge(prerequisite, node)

    if not nx.is_directed_acyclic_graph(graph):
        cycle = nx.find_cycle(graph, orientation="original")
        raise ValueError(f"dependency cycle detected: {cycle}")

    return list(nx.lexicographical_topological_sort(graph, key=lambda item: str(item)))
