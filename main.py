from typing import List
from py2neo import Graph, Path
from pydantic import BaseModel
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles


app = FastAPI()
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

graph = Graph("bolt://localhost:7687", auth=("neo4j", "cookie123"))


class ResultNode(BaseModel):
    id: str
    label: str
    size: int
    properties: dict

    def __eq__(self, other):
        return self.id == other.id


class ResultEdge(BaseModel):
    id: str
    from_: str  # from is a reserved word so re-map it below
    to: int

    def __eq__(self, other):
        return self.id == other.id

    class Config:
        fields = {
            'from_': 'from',
        }


class ResultPath(BaseModel):
    nodes: List[ResultNode]
    edges: List[ResultEdge]


@app.get("/", response_class=HTMLResponse)
def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request, "id": id})


@app.get("/data")
def read_data():
    result = ResultPath(
        nodes=[],
        edges=[],
    )
    data = graph.run("MATCH p=(t:Taxonomy)-[:IS_IN*1..3]->(n:Kingdom {complete_name: 'Fungi'}) RETURN p").data()
    for path in data:
        path = path['p']  # type: Path
        for node in path.nodes:
            size = 1 / node['level'] if node['level'] else 1
            result_node = ResultNode(
                id=node.identity,
                properties=node,
                label=node['vernacular_name'],
                size=size,
            )
            if result_node not in result.nodes:
                result.nodes.append(result_node)
        for rel in path.relationships:
            result_edge = ResultEdge(**{
                'id': rel.identity, 'from': rel.start_node.identity, 'to': rel.end_node.identity
            })
            if result_edge not in result.edges:
                result.edges.append(result_edge)
    return result


@app.get("/kingdoms")
def read_kingdoms():
    return graph.run("MATCH (k:Kingdom) RETURN k.complete_name as name").data()
