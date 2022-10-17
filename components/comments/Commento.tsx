import React, { useMemo, useState } from 'react';

import siteMetadata from '@/data/siteMetadata';
import { PostFrontMatter } from 'types/PostFrontMatter';
import { useTheme } from 'next-themes';
import ReactCommento from './commento/ReactCommento';

interface Props {
  frontMatter: PostFrontMatter;
}

const Commento = ({ frontMatter }: Props) => {
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
      <ReactCommento
        url={siteMetadata.comment.commentoConfig.url}
        pageId={frontMatter.slug}
      />
    </div>
  );
};

export default Commento;
