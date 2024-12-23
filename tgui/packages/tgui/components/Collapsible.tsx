/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { ReactNode, useState } from 'react';

import { Box, BoxProps } from './Box';
import { Button } from './Button';

type Props = Partial<{
  buttons: ReactNode;
  open: boolean;
  title: ReactNode;
  icon: string;
  disabled: boolean; // BLUEMOON EDIT: Modern Player Panel
}> &
  BoxProps;

export function Collapsible(props: Props) {
  const { children, color, title, buttons, icon, disabled, ...rest } = props; // BLUEMOON EDIT: Modern Player Panel  //const { children, color, title, buttons, icon, ...rest } = props;
  const [open, setOpen] = useState(props.open);

  return (
    <Box mb={1}>
      <div className="Table">
        <div className="Table__cell">
          <Button
            fluid
            color={color}
            icon={icon ? icon : open ? 'chevron-down' : 'chevron-right'}
            disabled={disabled} // BLUEMOON EDIT: Modern Player Panel
            onClick={() => setOpen(!open)}
            {...rest}
          >
            {title}
          </Button>
        </div>
        {buttons && (
          <div className="Table__cell Table__cell--collapsing">{buttons}</div>
        )}
      </div>
      {open &&
        // BLUEMOON EDIT: Modern Player Panel
        !disabled && (
          // BLUEMOON EDIT: Modern Player Panel
          <Box mt={1}>{children}</Box>
        )}
    </Box>
  );
}
