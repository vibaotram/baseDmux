import argparse
import os
import shutil
import sys
import subprocess
from ruamel.yaml import YAML


yaml=YAML()

def version():
    version_store = os.path.join(os.path.dirname(__file__), 'version.py')
    version = open(version_store, 'r').read()
    return version

def read_outdir(profile):
    with open(os.path.join(profile, "config.yaml"), "r") as yml:
        profileyml = yaml.safe_load(yml)
    with open(profileyml['configfile'], "r") as yml:
        configyml = yaml.safe_load(yml)
    return configyml['OUTDIR']

def read_profile(profile, keyword):
    with open(os.path.join(profile, "config.yaml"), "r") as yml:
        profileyml = yaml.safe_load(yml)
    return profileyml[keyword]

def main():
    cwd = os.getcwd()
    __version__ = version()
    parser = argparse.ArgumentParser(description='Run baseDmux version {}... See https://github.com/vibaotram/baseDmux/blob/master/README.md for more details'.format(__version__))
    # parser.add_argument('-r', '--readme', action='store_true', help='print README')
    parser.add_argument('-v', '--version', action='version', version=f'%(prog)s {__version__}')
    # parser.add_argument('-t', '--check_version_tools', action='store_true', help='check version for the tools of baseDmux')

    subparsers = parser.add_subparsers(dest='cmd')
    # subparsers.required = True

    parser_configure = subparsers.add_parser('configure', help='edit config file and profile')
    parser_configure.add_argument(help='path to the folder to contain config file and profile you want to create', dest='dir')
    parser_configure.add_argument('--edit', help='optional, open file with editor (nano, vim, gedit, etc.)', nargs='?', dest='editor')
    parser_configure.add_argument('--mode', choices=['local', 'cluster', 'slurm'], help='local or cluster or slurm', dest='mode', required=True, action='store')
    parser_configure.add_argument('--barcodes_by_genome', help='optional, create a tabular file containing information of barcodes for each genome)', action='store_true', dest='tab_file')

    parser_run = subparsers.add_parser('run', help='run baseDmux')
    parser_run.add_argument(nargs=1, action='store', dest='profile_dir', help='profile folder to run baseDmux')
    parser_run.add_argument('--snakemake_report', action='store_true', dest='report', help='optionally, create snakemake report')

    parser_dryrun = subparsers.add_parser('dryrun', help='dryrun baseDmux')
    parser_dryrun.add_argument(nargs=1, action='store', dest='profile_dir', help='profile folder to dryrun baseDmux')


    parser_tools = subparsers.add_parser('version_tools', help='check version for the tools of baseDmux')

    args = parser.parse_args()
    cmd = args.cmd
    # print(args)
    workdir = os.path.dirname(__file__)
    # print(workdir)
    snakefile = os.path.join(workdir, 'data/Snakefile')
    snakefile_tools = os.path.join(workdir, 'data/Snakefile_tools')
    source_config = os.path.join(workdir, 'data/config.yaml')
    source_profile = os.path.join(workdir, 'data/profile')
    source_barcode_table = os.path.join(workdir, 'data/barcodeByGenome_sample.tsv')
    # source_conda = os.path.join(workdir, 'data/conda')

    if cmd == 'configure':
        dir = args.dir
        dir = os.path.join(cwd, dir)
        os.makedirs(dir)

        ## copy barcodeByGenome.tsv if called
        if args.tab_file:
            table = os.path.join(dir, "barcodeByGenome.tsv")
            shutil.copyfile(source_barcode_table, table)
            if args.editor:
                os.system('{editor} {table}'.format(editor=args.editor, table=table))

        ## copy config file
        config = os.path.join(dir, 'workflow_parameters.yaml')
        print('copy sample workflow_parameters.yaml of baseDmux to {config}'.format(config=config))
        shutil.copyfile(source_config, config)
        if args.tab_file:
            with open(config, 'r') as cf:
                read_config = yaml.load(cf)
            read_config['RULE_GET_READS_PER_GENOME']['BARCODE_BY_GENOME'] = table
            with open(config, 'w') as cf:
                yaml.dump(read_config, cf)
        if args.editor:
            os.system('{editor} {config}'.format(editor=args.editor, config=config))


        ## copy profile
        profile = os.path.join(dir, 'profile')
        os.makedirs(profile)
        print(f'copy sample profile of baseDmux to {profile}')
        profile_config = os.path.join(profile, 'config.yaml')
        if args.mode == 'local':
            files = ['config.yaml']
            source_profile = os.path.join(source_profile, 'local')
        elif args.mode == 'cluster':
            source_profile = os.path.join(source_profile, 'cluster')
            files = ['cluster.json', 'config.yaml', 'jobscript.sh', 'submission_wrapper.py']
        elif args.mode == 'slurm':
            source_profile = os.path.join(source_profile, 'cluster')
            files = ['cluster.json', 'slurm/config.yaml', 'jobscript.sh', 'slurm/slurm_wrapper.py', 'slurm/slurm_status.py']
        for file in files:
            shutil.copy(os.path.join(source_profile, file), os.path.join(profile, os.path.basename(file)))

        ## change configfile in profile to workflow_parameters.yaml
        ## change cluster-related file path
        with open(profile_config, 'r') as yml:
            profileyml = yaml.load(yml)
            profileyml['configfile'] = '{}'.format(config)
            if args.mode == 'local':
                pass
            elif args.mode == 'cluster':
                profileyml['cluster-config'] = profileyml['cluster-config'].replace('data/profile/cluster/cluster.json', os.path.join(profile, 'cluster.json'))
                profileyml['cluster'] = profileyml['cluster'].replace('data/profile/cluster/submission_wrapper.py', os.path.join(profile, 'submission_wrapper.py'))
            elif args.mode == 'slurm':
                profileyml['cluster'] = profileyml['cluster'].replace('data/profile/cluster/slurm/slurm_wrapper.py', os.path.join(profile, 'slurm_wrapper.py'))
                profileyml['cluster'] = profileyml['cluster'].replace('config-test.yaml', config)
                profileyml['cluster-status'] = profileyml['cluster-status'].replace('data/profile/cluster/slurm/slurm_status.py', os.path.join(profile, 'slurm_status.py'))
            else:
                raise ValueError('impossible')

        print('profile config: {}'.format(profileyml))
        with open(profile_config, 'w') as yml:
            yaml.dump(profileyml, yml)

        for file in files:
            if args.editor:
                os.system('{editor} {profile}/{file}'.format(editor = args.editor, profile = profile, file = os.path.basename(file)))


    if cmd == 'run':
        print('run baseDmux')
        profile = args.profile_dir[0]
        profile = os.path.join(cwd, profile)
        configfile = read_profile(profile, 'configfile')
        run_snakemake = 'snakemake -s {snakefile} -d {workdir} --profile {profile} --configfile {configfile}'.format(snakefile=snakefile, profile=profile, workdir=workdir, configfile=configfile)
        # print(run_snakemake)
        snakemake_exit = os.system(run_snakemake)
        if snakemake_exit == 0 and args.report:
            reportfile = os.path.join(read_outdir(profile), 'report/snakemake_report.html')
            run_report = 'snakemake -s {snakefile} --profile {profile} --report {reportfile} -d {workdir}'.format(snakefile=snakefile, profile=profile, reportfile=reportfile, workdir=workdir)
            os.system(run_report)
        elif snakemake_exit != 0 and args.report:
            print('No snakemake report is created because baseDmux workflow failed!')


    if cmd == 'dryrun':
        print('dryrun baseDmux')
        profile = args.profile_dir[0]
        profile = os.path.join(cwd, profile)
        configfile = read_profile(profile, 'configfile')
        dryrun_snakemake = 'snakemake -s {snakefile} -d {workdir} --profile {profile} -n --configfile {configfile}'.format(snakefile=snakefile, profile=profile, workdir=workdir, configfile=configfile)
        os.system(dryrun_snakemake)

    if cmd == 'barcodes_by_genome':
        table = args.tab_file
        shutil.copyfile(source_barcode_table, table)
        if args.editor:
            os.system('{editor} {table}'.format(editor=args.editor, table=table))

    if cmd == 'version_tools':
        check_tools = ['snakemake', '-s', snakefile_tools, 'check_version_tools', '--use-singularity', '--use-conda', '-d', workdir, '--quiet']
        subprocess.call(check_tools, stderr=subprocess.DEVNULL)

    if cmd == None and len(sys.argv[1:]) == 0:
        parser.print_help()

    # print(cmd)

if __name__ == '__main__':
    main()

#TODO:
# - conda install -c conda-forge ruamel.yaml