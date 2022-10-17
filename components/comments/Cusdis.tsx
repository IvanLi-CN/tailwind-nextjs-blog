import React, { useMemo, useState } from 'react';

import siteMetadata from '@/data/siteMetadata';
import { PostFrontMatter } from 'types/PostFrontMatter';
import { ReactCusdis } from 'react-cusdis';
import { useTheme } from 'next-themes';

interface Props {
  frontMatter: PostFrontMatter;
}

const Cusdis = ({ frontMatter }: Props) => {
  const { resolvedTheme } = useTheme();
  const commentsTheme = useMemo(() => {
    switch (resolvedTheme) {
      case 'light':
      case 'dark':
        return resolvedTheme;
      default:
        return 'auto';
    }
  }, [resolvedTheme]);
  return (
    <div className="my-2">
      <ReactCusdis
        key={commentsTheme}
        lang={siteMetadata.language?.toLocaleLowerCase()}
        attrs={{
          appId: siteMetadata.comment.cusdisConfig.appId,
          host: siteMetadata.comment.cusdisConfig.host,
          pageId: frontMatter.slug,
          pageUrl: window.location.href,
          pageTitle: frontMatter.title,
          theme: commentsTheme,
        }}
      />
    </div>
  );
};

export default Cusdis;
