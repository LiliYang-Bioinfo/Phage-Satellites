# Workflow: 1. Get the genbank files from genbank ID by Entrez eftch; 2. Process the genbank files for Assembly ID; 3. Obtaining the ftp link from Assembly ID

# Step1: Generate the script for efetch 
awk '{print $1}' PICI_prediction | grep -v '\*' > tmp1 
sort -u tmp1 > tmp2 
echo "echo \"efetch -db nuccore -id \$1 -format gb >> \$1.gb\"" > run.sh 
cat tmp2 | xargs -n 1 sh tmp3 > cmd_efetch 
sh cmd_efetch 
# Manually check the result 

# Step2: Process the genbank files obtained by efetch 
## collect all genbank file into one 
cat *gb > all 
mv all all.gb 
mkdir gb_files 
mv *gb gb_files 
cd gb_files 
## Generate python script for obtaining the Assembly ID from genbank file 
echo "from Bio import GenBank
import sys 
args = sys.argv
with open(args[1]) as handle:
    for record in GenBank.parse(handle):
        print(record.accession, record.dblinks)" > gb_parse.py 
python gb_parse.py all.gb > parse_out 
## Example output by the script: "['NC_002951'] ['BioProject: PRJNA224116', 'BioSample: SAMN02603996', 'Assembly: GCF_000012045.1']"
## Process the output 
sort -u parse_out > tmp1 
mv tmp1 parse_out 
grep -o "Assembly.*'" parse_out > tmp1 
sort -u tmp1 > tmp2 
awk '{print $2}' tmp2| cut -d "'" -f 1 > Assembly_list 
rm tmp* 

# Step3: Obtaining the ftp link from Assembly ID
cut -b '5-7' Assembly_list> tmp1 
cut -b '8-10' Assembly_list> tmp2
cut -b '11-13' Assembly_list> tmp3
paste Assembly_list tmp1 tmp2 tmp3 > tmp4 

## Manully edit the file "cmd_wget"
vi cmd_wget 
## cmd_wget: echo "wget -q ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/$2/$3/$4/ && mv index.html html && grep -o 'href.*\"' html "
cat tmp4 | xargs -n 4 sh cmd_wget > tmp1
sh tmp1 1>out_href 2>err_href
## Manual check the result in "out_href"
cut -d '"' -f 2 out_href > tmp1 
awk -F "/" '{print "wget -q "$0""$(NF-1)"_genomic.fna.gz && echo \""$(NF-1)": OK\""}' tmp1 > cmd_get_assembly
