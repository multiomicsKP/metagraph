# metagraph
A utility for deriving a metagraph from node and edge tsv files.

The Biomedical Translator project, funded by NCATS, generates, uses and shares knowledge graphs (KG).
One standard exchange format involves two tsv files, one describing graph nodes and the other the edges.
This utility studies the two tsv files representing a KG, identifies node types and which predicates connect these node types, and produces a metagraph representing this structure.
The metagraph is saved in graphml format, which can be opened in utilities like yEd for visualization.

## Installing

To install this software, simply clone this repository:  
	`git clone https://github.com/multiomicsKP/metagraph`

## Usage

1. Create the graphml file:  
  `bin/metagraph.pl path/to/nodes_file.tsv path/to/edges_file.tsv > path/to/metagraph_file.graphml`
 
2. Open the resulting graphml file in yEd.
3. In yEd, select menu **Tools**, command **Fit Node to Label**, unselect 'Ignore Width' and 'Ignore Height' if they're selected, and click **OK**.
4. Perform a layout. For example, select menu **Layout**, command **Circular**, and press **OK**.
