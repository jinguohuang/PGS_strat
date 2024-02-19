# script to liftover cleaned UKBB from hg19 to hg38
# Step1: Convert summary statistics to vcf format
# bcftools +munge
# This step will convert pvalue to -log10
# Colnames: CHR->CHROM, BP->POS, A1 -> ALT, A2 -> REF, N->NS, BETA->ES, SE->SE, PVAL->LP
# Step2: Liftover vcf format
# bcftools +liftover
# Step3: Convert vcf format back to the tsv format 
# bcftools query
# Convert -log10Pval back
# zip file

trait=$1
echo "liftover ${trait} ..."
zcat ../1_cleaned_data/${trait}_ukbb.tsv | \
bcftools +munge --no-version -Ov -C colheaders.tsv -f $HOME/GRCh37/human_g1k_v37.fasta -s ukbb_test | \
bcftools +liftover --no-version -Ov -- -s $HOME/GRCh37/human_g1k_v37.fasta \
    -f $HOME/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna \
    -c $HOME/GRCh38/hg19ToHg38.over.chain.gz | \
bcftools query -f '%CHROM\t%POS\t%REF\t%ALT[\t%NS\t%ES\t%SE\t%LP]\n' | \
awk -F"\t" -v OFS="\t" '{$8=10^(-$8); print}' | \
awk 'BEGIN{print "CHR\tBP\tA2\tA1\tN\tBETA\tSE\tPVAL"}1' |\
gzip > ${trait}_ukbb.hg38.tsv.gz

