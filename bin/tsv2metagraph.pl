#!/usr/bin/perl
$|=1;
use strict;
use JSON;

###
#
# This script studies a pair of TSV files (nodes and edges) to derive their metagraph representation. It makes various assumptions about format, including the presence of biolink CURIEs.
# It produces a graph in graphml format, printed to STDOUT.
#
# Use: bin/tsv2metagraph.pl path_to/nodes.tsv path_to/edges.tsv > metagraph.graphml
# The optional 3rd parameter is the delimiter to use, defaulting to a tab.
#
###


my($nodesFile, $edgesFile, $delim) = @ARGV;
$delim ||= "\t";
my(@nodes, @edges, %nodei);
my $ind = "  ";
my %shape = qw/NodeType ellipse CURIE rectangle/;
my %color = qw/NodeType #FF9900 CURIE #FFCC00/;
my %lineType = qw/NodeNode line NodeCURIE dashed/;


# nodes:
# id	name	category
my($nodeHeaders, $nodeCols) = openFile($nodesFile);
my $idcol = $nodeCols->{'id'};
my $catcol = $nodeCols->{'category'};
my(@v, $id, $cat, %category, $class, %classCount, %catCount, %ccCount);
while (<F>) {
	chomp;
	@v = split /$delim/;
	$id = $v[$idcol];
	$cat = $v[$catcol];
	if ($cat =~ /biolink:(.+)/) {
		$cat = $1;
	}
	if ($id =~ /(.+?):./) {
		$class = $1;
	} else {
		$class = "?";
	}
	$category{$id} = $cat;
	$classCount{$class}++;
	$catCount{$cat}++;
	$ccCount{$cat}{$class}++;
}
close F;

foreach my $cat (sort keys %catCount) {
	#push @nodes, $cat;
	$nodei{$cat} = scalar @nodes;
	push @nodes, {'name' => $cat, 'class' => 'NodeType', 'count' => $catCount{$cat}};
	#print join(" ", $nodei{$cat}, $cat, 'NodeType', $catCount{$cat}), "\n";
}
foreach my $class (sort keys %classCount) {
	#push @nodes, $class;
	$nodei{$class} = scalar @nodes;
	push @nodes, {'name' => $class, 'class' => 'CURIE', 'count' => $classCount{$class}};
	#print join(" ", $nodei{$class}, $class, 'CURIE', $classCount{$class}), "\n";
}

#print "#\n";

foreach my $cat (sort keys %ccCount) {
	foreach my $class (sort keys %{$ccCount{$cat}}) {
		push @edges, {'source' => $nodei{$cat}, 'target' => $nodei{$class}, 'relation' => 'uses_curie', 'count' => $ccCount{$cat}{$class}, 'type' => 'NodeCURIE'};
		#print join(" ", $nodei{$cat}, $nodei{$class}, $ccCount{$cat}{$class}), "\n";
	}
}

# edges:
# subject	predicate	object	relation	subject_name	object_name	category
my($edgeHeaders, $edgeCols) = openFile($edgesFile);
my $subjcol = $edgeCols->{'subject'};
my $predcol = $edgeCols->{'predicate'};
my $objcol = $edgeCols->{'object'};
my(@v, $subj, $pred, $obj, $sclass, $oclass, %eCount);
while (<F>) {
	chomp;
	@v = split /$delim/;
	$subj = $v[$subjcol];
	$pred = $v[$predcol];
	$obj = $v[$objcol];
	$sclass = $oclass = "?";
	if ($subj =~ /(.+?):./) {
		$sclass = $1;
	}
	if ($obj =~ /(.+?):./) {
		$oclass = $1;
	}
	if ($pred =~ /biolink:(.+)/) {
		$pred = $1;
	}

	#$eCount{$sclass}{$oclass}++;
	$eCount{$category{$subj}}{$category{$obj}}{$pred}++;
}
close F;

foreach my $sclass (sort keys %eCount) {
	foreach my $oclass (sort keys %{$eCount{$sclass}}) {
		foreach my $pred (sort keys %{$eCount{$sclass}{$oclass}}) {
			push @edges, {'source' => $nodei{$sclass}, 'target' => $nodei{$oclass}, 'relation' => $pred, 'count' => $eCount{$sclass}{$oclass}{$pred}, 'type' => 'NodeNode'};
		#print join("\t", $nodei{$sclass}, $nodei{$oclass}, $eCount{$sclass}{$oclass}), "\n";
		}
	}
}

printGraphml(\@nodes, \@edges);



sub openFile {
	my($file) = @_;

	if ($file =~ /\.gz$/) {
		 open F, "gunzip -c $file |";
	} else {
		open F, $file;
	}
	$_ = <F>;
	chomp;
	my @headers = split /$delim/;
	my %col;
	$col{$headers[$_]} = $_ foreach (0..$#headers);

	return \@headers, \%col;
}


sub printGraphml {
        my($nodes, $edges) = @_;

        print "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n";
	#print "<graphml>\n";
	print <<END_BLOCK;
  <graphml xmlns="http://graphml.graphdrawing.org/xmlns" xmlns:java="http://www.yworks.com/xml/yfiles-common/1.0/java" xmlns:sys="http://www.yworks.com/xml/yfiles-common/markup/primitives/2.0" xmlns:x="http://www.yworks.com/xml/yfiles-common/markup/2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:y="http://www.yworks.com/xml/graphml" xmlns:yed="http://www.yworks.com/xml/yed/3" xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns http://www.yworks.com/xml/schema/graphml/1.1/ygraphml.xsd">
  <key for="port" id="d0" yfiles.type="portgraphics"/>
  <key for="port" id="d1" yfiles.type="portgeometry"/>
  <key for="port" id="d2" yfiles.type="portuserdata"/>
  <key attr.name="url" attr.type="string" for="node" id="d3"/>
  <key attr.name="description" attr.type="string" for="node" id="d4"/>
  <key for="node" id="d5" yfiles.type="nodegraphics"/>
  <key for="graphml" id="d6" yfiles.type="resources"/>
  <key attr.name="url" attr.type="string" for="edge" id="d7"/>
  <key attr.name="description" attr.type="string" for="edge" id="d8"/>
  <key for="edge" id="d9" yfiles.type="edgegraphics"/>
END_BLOCK
        print "$ind<graph edgedefault=\"directed\" id=\"G\">\n";
        printNodes($nodes);
        printEdges($edges);
        print "$ind</graph>\n";
        print "</graphml>\n";
}
sub printNodes {
        my($nodes) = @_;
        foreach my $node (0..$#$nodes) {
                my $class = $nodes->[$node]{'class'};
		my $name = join("\n", $nodes->[$node]{'name'}, $nodes->[$node]{'count'});
		$_ = $name;
		s/[a-z]//g;
		my $width = 7*length($name)+4*length();
                print $ind x 2, "<node id=\"n$node\">\n";
                print $ind x 3, "<data key=\"d5\">\n";
                print $ind x 4, "<y:ShapeNode>\n";
		print $ind x 5, "<y:Geometry height=\"30.0\" width=\"$width\"/>\n";
                print $ind x 5, "<y:Fill color=\"$color{$class}\" transparent=\"false\"\/>\n";
                print $ind x 5, "<y:BorderStyle color=\"#000000\" raised=\"false\" type=\"line\" width=\"1.0\"\/>\n";
                print $ind x 5, "<y:Shape type=\"$shape{$class}\"/>\n";
		#print $ind x 5, "<y:NodeLabel alignment=\"center\" autoSizePolicy=\"content\" fontFamily=\"Dialog\" fontSize=\"12\" fontStyle=\"plain\" hasBackgroundColor=\"false\" hasLineColor=\"false\" horizontalTextPosition=\"center\" iconTextGap=\"4\" modelName=\"custom\" textColor=\"#000000\" verticalTextPosition=\"bottom\" visible=\"true\" xml:space=\"preserve\">${name}<y:LabelModel><y:SmartNodeLabelModel distance=\"4.0\"/></y:LabelModel><y:ModelParameter><y:SmartNodeLabelModelParameter labelRatioX=\"0.0\" labelRatioY=\"0.0\" offsetX=\"0.0\" offsetY=\"0.0\" upX=\"0.0\" upY=\"-1.0\"/></y:ModelParameter></y:NodeLabel>\n";
		print $ind x 5, <<NODE_BLOCK;
<y:NodeLabel alignment="center" autoSizePolicy="content" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" height="18.1328125" horizontalTextPosition="center" iconTextGap="4" modelName="custom" textColor="#000000" verticalTextPosition="bottom" visible="true" width="$width" x="5" xml:space="preserve" y="6">${name}<y:LabelModel><y:SmartNodeLabelModel distance="4.0"/></y:LabelModel><y:ModelParameter><y:SmartNodeLabelModelParameter labelRatioX="0.0" labelRatioY="0.0" nodeRatioX="1.1102230246251565E-16" nodeRatioY="0.0" offsetX="0.0" offsetY="0.0" upX="0.0" upY="-1.0"/></y:ModelParameter></y:NodeLabel>
NODE_BLOCK
                print $ind x 4, "</y:ShapeNode>\n";
                print $ind x 3, "</data>\n";
                print $ind x 2, "</node>\n";
        }
}
sub printEdges {
        my($edges) = @_;
        foreach my $edge (0..$#$edges) {
                my $source = $edges->[$edge]{'source'};
                my $target = $edges->[$edge]{'target'};
		my $relation = $edges->[$edge]{'relation'};
		my $count = $edges->[$edge]{'count'};
		my $width = log($count)/2;
		$width = 1 if $width<1;
		my $type = $lineType{$edges->[$edge]{'type'}};
		my $name = join("\n", $relation, $count);
                print $ind x 2, "<edge id=\"e$edge\" source=\"n$source\" target=\"n$target\">\n";
		print $ind x 3, "<data key=\"d9\">\n";
		print $ind x 4, "<y:PolyLineEdge>\n";
		print $ind x 5, "<y:LineStyle color=\"#000000\" type=\"$type\" width=\"$width\"/>\n";
		print $ind x 5, "<y:Arrows source=\"none\" target=\"standard\"/>\n";
		print $ind x 5, <<EDGE_BLOCK;
<y:EdgeLabel alignment="center" distance="2.0" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" height="32.265625" horizontalTextPosition="center" iconTextGap="4" modelName="custom" preferredPlacement="anywhere" ratio="0.5" textColor="#000000" verticalTextPosition="bottom" visible="true" width="65.025390625" x="38.72458982909495" xml:space="preserve" y="-15.157028658501666">$name<y:LabelModel><y:RotatedDiscreteEdgeLabelModel angle="0.0" autoRotationEnabled="true" candidateMask="128" distance="2.0" positionRelativeToSegment="false"/></y:LabelModel><y:ModelParameter><y:RotatedDiscreteEdgeLabelModelParameter position="center"/></y:ModelParameter><y:PreferredPlacementDescriptor angle="0.0" angleOffsetOnRightSide="0" angleReference="absolute" angleRotationOnRightSide="co" distance="-1.0" frozen="true" placement="anywhere" side="anywhere" sideReference="relative_to_edge_flow"/></y:EdgeLabel>
EDGE_BLOCK
		print $ind x 4, "</y:PolyLineEdge>\n";
		print $ind x 3, "</data>\n";
                print $ind x 2, "</edge>\n";
        }
}
