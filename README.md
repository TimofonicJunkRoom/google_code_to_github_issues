# NAME

`google_code_to_github_issues`

# SYNOPSIS

    # Extract issue pages to ./issues/
    # Downloads from Internet Archive and removes Internet Archive page elements
    % bin/download_issues_from_google_code_wayback_archive.pl 

    # scrape individual pages and extract issue data
    % (cd issues; ../bin/parse_google_code_issues_to_yaml.pl $(ls | sort -n) > ../issues.yaml)

    # manually render templates with tt-render:
    % tt-render --path=templates/ --data=issues.yaml issues.mkdn

    # render body for github issues
    % bin/render_github_issue_template < issues.yaml > issues_with_data.yaml

    # create github issues from yaml

# ABOUT

Quick and Dirty scripts to migrate issues for WWW::Mechanzie from Google Code to Github via InternetArchive.

The project was migrated to Github and removed from Google code in anticipation of the Google Code shutdown.  The Google Code exporter was not run to migrate the issues.

If the project hadn't been removed, it would still be available to scrape directly from the Google Code Archive.  Internet Archive has spidered the updated Google Code Archive pages and cached the redirects served by CGA for the removed project.  The downloader needed to start with a specific revision of the project archive prior to the removal of the project.

